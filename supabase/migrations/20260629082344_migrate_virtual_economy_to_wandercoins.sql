alter table public.products
add column wandercoin_price_amount numeric(12,2);

update public.products
set wandercoin_price_amount = price_amount
where upper(currency_code) = 'USD'
  and price_amount is not null;

alter table public.products
add constraint products_wandercoin_price_amount_positive
check (
  wandercoin_price_amount is null
  or wandercoin_price_amount > 0
);

alter table public.virtual_order_items
add column source_price_amount numeric(12,2),
add column source_currency_code text;

update public.virtual_order_items
set
  source_price_amount = unit_price_amount,
  source_currency_code = currency_code;

alter table public.profiles
drop constraint if exists profiles_virtual_balance_currency_format;

alter table public.virtual_orders
drop constraint if exists virtual_orders_currency_code_format;

alter table public.virtual_order_items
drop constraint if exists virtual_order_items_currency_code_format;

update public.profiles
set
  virtual_balance_currency = 'WCN',
  home_currency_set_at = coalesce(
    home_currency_set_at,
    timezone('utc', now())
  );

update public.virtual_orders
set currency_code = 'WCN';

update public.virtual_order_items
set currency_code = 'WCN';

update public.virtual_balance_transactions
set currency_code = 'WCN';

alter table public.profiles
alter column virtual_balance_currency set default 'WCN',
alter column home_currency_set_at set default timezone('utc', now()),
alter column home_currency_set_at set not null,
add constraint profiles_virtual_balance_currency_wandercoins
check (virtual_balance_currency = 'WCN');

alter table public.virtual_orders
alter column currency_code set default 'WCN',
alter column currency_code set not null,
add constraint virtual_orders_currency_code_wandercoins
check (currency_code = 'WCN');

alter table public.virtual_order_items
alter column currency_code set default 'WCN',
alter column currency_code set not null,
add constraint virtual_order_items_currency_code_wandercoins
check (currency_code = 'WCN'),
add constraint virtual_order_items_source_currency_code_format
check (
  source_currency_code is null
  or source_currency_code ~ '^[A-Z]{3}$'
),
add constraint virtual_order_items_source_price_amount_positive
check (
  source_price_amount is null
  or source_price_amount > 0
);

alter table public.virtual_balance_transactions
drop constraint if exists virtual_balance_transactions_currency_code_check;

alter table public.virtual_balance_transactions
alter column currency_code set default 'WCN',
add constraint virtual_balance_transactions_currency_code_wandercoins
check (currency_code = 'WCN');

delete from public.supported_currencies;

insert into public.supported_currencies (
  currency_code,
  display_name,
  symbol,
  minor_unit,
  sort_order,
  is_active
)
values (
  'WCN',
  'WanderCoins',
  'W',
  2,
  1,
  true
);

drop trigger if exists virtual_orders_require_home_currency
on public.virtual_orders;

drop function if exists private.ensure_order_home_currency();

create or replace function private.ensure_order_uses_wandercoins()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.currency_code <> 'WCN' then
    raise exception using
      errcode = 'P0001',
      message = 'Virtual orders must use WanderCoins';
  end if;

  if not exists (
    select 1
    from public.profiles profile
    where profile.id = new.user_id
      and profile.virtual_balance_currency = 'WCN'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'WanderCoin wallet was not found';
  end if;

  return new;
end;
$$;

revoke all on function private.ensure_order_uses_wandercoins()
from public, anon, authenticated, service_role;

create trigger virtual_orders_require_wandercoins
before insert or update of currency_code
on public.virtual_orders
for each row
execute function private.ensure_order_uses_wandercoins();

create or replace function public.get_my_wallet()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'balance', jsonb_build_object(
      'amount', profile.virtual_balance_amount,
      'currency_code', 'WCN',
      'unit', 'WanderCoins'
    ),
    'home_currency_selected', true,
    'home_currency_selected_at', profile.home_currency_set_at
  )
  from public.profiles profile
  where profile.id = (select auth.uid())
    and (select auth.uid()) is not null;
$$;

revoke all on function public.get_my_wallet()
from public, anon, service_role;

grant execute on function public.get_my_wallet()
to authenticated;

create or replace function public.set_home_currency(
  p_user_id uuid,
  p_currency_code text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
begin
  if upper(trim(coalesce(p_currency_code, ''))) <> 'WCN' then
    raise exception using
      errcode = 'P0001',
      message = 'WanderCoins are the only virtual wallet denomination';
  end if;

  update public.profiles
  set
    virtual_balance_currency = 'WCN',
    home_currency_set_at = coalesce(
      home_currency_set_at,
      timezone('utc', now())
    )
  where id = p_user_id
  returning *
  into v_profile;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'User profile was not found';
  end if;

  return jsonb_build_object(
    'home_currency', jsonb_build_object(
      'currency_code', 'WCN',
      'selected_at', v_profile.home_currency_set_at
    ),
    'balance', jsonb_build_object(
      'amount', v_profile.virtual_balance_amount,
      'currency_code', 'WCN',
      'unit', 'WanderCoins'
    )
  );
end;
$$;

revoke all on function public.set_home_currency(uuid, text)
from public, anon, authenticated;

grant execute on function public.set_home_currency(uuid, text)
to service_role;

create or replace function public.place_virtual_order(
  p_user_id uuid,
  p_product_id uuid,
  p_quantity integer,
  p_idempotency_key uuid,
  p_manual_price_amount numeric default null,
  p_manual_currency_code text default null
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_product public.products%rowtype;
  v_order public.virtual_orders%rowtype;
  v_unit_price numeric(12,2);
  v_total numeric(12,2);
  v_balance_after numeric(12,2);
  v_price_source text;
begin
  if p_quantity is null or p_quantity < 1 or p_quantity > 99 then
    raise exception using
      errcode = 'P0001',
      message = 'Quantity must be between 1 and 99';
  end if;

  if p_idempotency_key is null then
    raise exception using
      errcode = 'P0001',
      message = 'An idempotency key is required';
  end if;

  select *
  into v_profile
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'User profile was not found';
  end if;

  select *
  into v_order
  from public.virtual_orders
  where user_id = p_user_id
    and idempotency_key = p_idempotency_key;

  if found then
    return jsonb_build_object(
      'order', to_jsonb(v_order),
      'items', (
        select coalesce(
          jsonb_agg(to_jsonb(item) order by item.created_at),
          '[]'::jsonb
        )
        from public.virtual_order_items item
        where item.virtual_order_id = v_order.id
      ),
      'balance', jsonb_build_object(
        'amount', v_profile.virtual_balance_amount,
        'currency_code', 'WCN',
        'unit', 'WanderCoins'
      ),
      'idempotent_replay', true
    );
  end if;

  select *
  into v_product
  from public.products
  where id = p_product_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'Product was not found';
  end if;

  if v_product.wandercoin_price_amount is not null then
    v_unit_price = v_product.wandercoin_price_amount;
    v_price_source = 'fixed USD-to-WanderCoin';
  else
    v_unit_price = p_manual_price_amount;
    v_price_source = 'manual WanderCoin';
  end if;

  if v_unit_price is null or v_unit_price <= 0 then
    raise exception using
      errcode = 'P0001',
      message = 'A positive WanderCoin price is required for this product';
  end if;

  v_total = round(v_unit_price * p_quantity, 2);

  if v_total > 9999999999.99 then
    raise exception using
      errcode = 'P0001',
      message = 'Order total is outside the supported WanderCoin range';
  end if;

  if v_profile.virtual_balance_amount < v_total then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Insufficient WanderCoin balance: available %s, required %s',
        v_profile.virtual_balance_amount,
        v_total
      );
  end if;

  v_balance_after = v_profile.virtual_balance_amount - v_total;

  update public.profiles
  set virtual_balance_amount = v_balance_after
  where id = p_user_id;

  insert into public.virtual_orders (
    user_id,
    status,
    total_amount,
    currency_code,
    placed_at,
    idempotency_key,
    balance_after_amount
  )
  values (
    p_user_id,
    'ordered',
    v_total,
    'WCN',
    timezone('utc', now()),
    p_idempotency_key,
    v_balance_after
  )
  returning *
  into v_order;

  insert into public.virtual_order_items (
    virtual_order_id,
    product_id,
    title_snapshot,
    image_url_snapshot,
    currency_code,
    unit_price_amount,
    source_currency_code,
    source_price_amount,
    quantity
  )
  values (
    v_order.id,
    v_product.id,
    v_product.title,
    v_product.image_url,
    'WCN',
    v_unit_price,
    v_product.currency_code,
    v_product.price_amount,
    p_quantity
  );

  insert into public.virtual_balance_transactions (
    user_id,
    virtual_order_id,
    transaction_type,
    amount_delta,
    balance_after_amount,
    currency_code,
    description
  )
  values (
    p_user_id,
    v_order.id,
    'purchase',
    -v_total,
    v_balance_after,
    'WCN',
    format(
      'WanderCoin purchase of %s x%s (%s price)',
      v_product.title,
      p_quantity,
      v_price_source
    )
  );

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'items', (
      select coalesce(
        jsonb_agg(to_jsonb(item) order by item.created_at),
        '[]'::jsonb
      )
      from public.virtual_order_items item
      where item.virtual_order_id = v_order.id
    ),
    'balance', jsonb_build_object(
      'amount', v_balance_after,
      'currency_code', 'WCN',
      'unit', 'WanderCoins'
    ),
    'idempotent_replay', false
  );
end;
$$;

revoke all on function public.place_virtual_order(
  uuid,
  uuid,
  integer,
  uuid,
  numeric,
  text
) from public, anon, authenticated;

grant execute on function public.place_virtual_order(
  uuid,
  uuid,
  integer,
  uuid,
  numeric,
  text
) to service_role;

create or replace function public.place_virtual_cart_order(
  p_user_id uuid,
  p_items jsonb,
  p_idempotency_key uuid
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_order public.virtual_orders%rowtype;
  v_item_count integer;
  v_product_count integer;
  v_unique_product_count integer;
  v_has_missing_fields boolean;
  v_has_invalid_quantity boolean;
  v_total numeric;
  v_balance_after numeric(12,2);
begin
  if p_idempotency_key is null then
    raise exception using
      errcode = 'P0001',
      message = 'An idempotency key is required';
  end if;

  if jsonb_typeof(p_items) is distinct from 'array' then
    raise exception using
      errcode = 'P0001',
      message = 'Cart items must be a JSON array';
  end if;

  v_item_count = jsonb_array_length(p_items);

  if v_item_count < 1 or v_item_count > 50 then
    raise exception using
      errcode = 'P0001',
      message = 'Cart must contain between 1 and 50 items';
  end if;

  begin
    select
      count(*),
      count(distinct item.product_id),
      bool_or(item.product_id is null or item.quantity is null),
      bool_or(
        item.quantity is null
        or item.quantity < 1
        or item.quantity > 99
      )
    into
      v_product_count,
      v_unique_product_count,
      v_has_missing_fields,
      v_has_invalid_quantity
    from jsonb_to_recordset(p_items) as item(
      product_id uuid,
      quantity integer,
      manual_coin_amount numeric,
      manual_price_amount numeric,
      manual_currency_code text
    );
  exception
    when invalid_text_representation or invalid_parameter_value then
      raise exception using
        errcode = 'P0001',
        message = 'Every cart item must be an object with a valid product ID';
  end;

  if v_product_count <> v_item_count or v_has_missing_fields then
    raise exception using
      errcode = 'P0001',
      message = 'Every cart item must contain a product ID and quantity';
  end if;

  if v_unique_product_count <> v_item_count then
    raise exception using
      errcode = 'P0001',
      message = 'Each product may only appear once in the cart';
  end if;

  if v_has_invalid_quantity then
    raise exception using
      errcode = 'P0001',
      message = 'Every quantity must be between 1 and 99';
  end if;

  select *
  into v_profile
  from public.profiles
  where id = p_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'User profile was not found';
  end if;

  select *
  into v_order
  from public.virtual_orders
  where user_id = p_user_id
    and idempotency_key = p_idempotency_key;

  if found then
    return jsonb_build_object(
      'order', to_jsonb(v_order),
      'items', (
        select coalesce(
          jsonb_agg(to_jsonb(item) order by item.created_at),
          '[]'::jsonb
        )
        from public.virtual_order_items item
        where item.virtual_order_id = v_order.id
      ),
      'balance', jsonb_build_object(
        'amount', v_profile.virtual_balance_amount,
        'currency_code', 'WCN',
        'unit', 'WanderCoins'
      ),
      'idempotent_replay', true
    );
  end if;

  select count(*)
  into v_product_count
  from jsonb_to_recordset(p_items) as item(product_id uuid)
  join public.products product
    on product.id = item.product_id;

  if v_product_count <> v_item_count then
    raise exception using
      errcode = 'P0001',
      message = 'One or more products were not found';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as item(
      product_id uuid,
      manual_coin_amount numeric,
      manual_price_amount numeric
    )
    join public.products product
      on product.id = item.product_id
    where coalesce(
      product.wandercoin_price_amount,
      item.manual_coin_amount,
      item.manual_price_amount
    ) is null
      or coalesce(
        product.wandercoin_price_amount,
        item.manual_coin_amount,
        item.manual_price_amount
      ) <= 0
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'A positive WanderCoin price is required for every unpriced product';
  end if;

  select round(
    sum(
      coalesce(
        product.wandercoin_price_amount,
        item.manual_coin_amount,
        item.manual_price_amount
      ) * item.quantity
    ),
    2
  )
  into v_total
  from jsonb_to_recordset(p_items) as item(
    product_id uuid,
    quantity integer,
    manual_coin_amount numeric,
    manual_price_amount numeric,
    manual_currency_code text
  )
  join public.products product
    on product.id = item.product_id;

  if v_total is null or v_total <= 0 or v_total > 9999999999.99 then
    raise exception using
      errcode = 'P0001',
      message = 'Cart total is outside the supported WanderCoin range';
  end if;

  if v_profile.virtual_balance_amount < v_total then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Insufficient WanderCoin balance: available %s, required %s',
        v_profile.virtual_balance_amount,
        v_total
      );
  end if;

  v_balance_after = v_profile.virtual_balance_amount - v_total;

  update public.profiles
  set virtual_balance_amount = v_balance_after
  where id = p_user_id;

  insert into public.virtual_orders (
    user_id,
    status,
    total_amount,
    currency_code,
    placed_at,
    idempotency_key,
    balance_after_amount
  )
  values (
    p_user_id,
    'ordered',
    v_total,
    'WCN',
    timezone('utc', now()),
    p_idempotency_key,
    v_balance_after
  )
  returning *
  into v_order;

  insert into public.virtual_order_items (
    virtual_order_id,
    product_id,
    title_snapshot,
    image_url_snapshot,
    currency_code,
    unit_price_amount,
    source_currency_code,
    source_price_amount,
    quantity
  )
  select
    v_order.id,
    item.product_id,
    product.title,
    product.image_url,
    'WCN',
    coalesce(
      product.wandercoin_price_amount,
      item.manual_coin_amount,
      item.manual_price_amount
    ),
    product.currency_code,
    product.price_amount,
    item.quantity
  from jsonb_to_recordset(p_items) as item(
    product_id uuid,
    quantity integer,
    manual_coin_amount numeric,
    manual_price_amount numeric,
    manual_currency_code text
  )
  join public.products product
    on product.id = item.product_id
  order by item.product_id;

  insert into public.virtual_balance_transactions (
    user_id,
    virtual_order_id,
    transaction_type,
    amount_delta,
    balance_after_amount,
    currency_code,
    description
  )
  values (
    p_user_id,
    v_order.id,
    'purchase',
    -v_total,
    v_balance_after,
    'WCN',
    format('WanderCoin cart purchase of %s products', v_item_count)
  );

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'items', (
      select coalesce(
        jsonb_agg(to_jsonb(item) order by item.created_at),
        '[]'::jsonb
      )
      from public.virtual_order_items item
      where item.virtual_order_id = v_order.id
    ),
    'balance', jsonb_build_object(
      'amount', v_balance_after,
      'currency_code', 'WCN',
      'unit', 'WanderCoins'
    ),
    'idempotent_replay', false
  );
end;
$$;

revoke all on function public.place_virtual_cart_order(
  uuid,
  jsonb,
  uuid
) from public, anon, authenticated;

grant execute on function public.place_virtual_cart_order(
  uuid,
  jsonb,
  uuid
) to service_role;
