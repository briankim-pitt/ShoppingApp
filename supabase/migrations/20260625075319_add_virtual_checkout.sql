alter table public.profiles
add column virtual_balance_amount numeric(12,2) not null default 1000.00,
add column virtual_balance_currency text not null default 'USD';

alter table public.profiles
add constraint profiles_virtual_balance_amount_nonnegative
check (virtual_balance_amount >= 0),
add constraint profiles_virtual_balance_currency_format
check (virtual_balance_currency ~ '^[A-Z]{3}$');

alter table public.products
add constraint products_price_amount_positive
check (price_amount is null or price_amount > 0),
add constraint products_currency_code_format
check (currency_code is null or currency_code ~ '^[A-Z]{3}$');

update public.virtual_orders
set status = 'ordered'
where status = 'created';

alter table public.virtual_orders
drop constraint if exists virtual_orders_status_check;

alter table public.virtual_orders
alter column status set default 'ordered',
add column idempotency_key uuid,
add column balance_after_amount numeric(12,2),
add constraint virtual_orders_status_check
check (
  status in (
    'ordered',
    'processing',
    'shipped',
    'out_for_delivery',
    'delivered',
    'cancelled'
  )
),
add constraint virtual_orders_total_amount_positive
check (total_amount > 0),
add constraint virtual_orders_currency_code_format
check (currency_code is null or currency_code ~ '^[A-Z]{3}$'),
add constraint virtual_orders_balance_after_nonnegative
check (balance_after_amount is null or balance_after_amount >= 0);

create unique index virtual_orders_user_id_idempotency_key_unique
on public.virtual_orders (user_id, idempotency_key)
where idempotency_key is not null;

alter table public.virtual_order_items
add constraint virtual_order_items_unit_price_positive
check (unit_price_amount > 0),
add constraint virtual_order_items_quantity_limit
check (quantity between 1 and 99),
add constraint virtual_order_items_currency_code_format
check (currency_code is null or currency_code ~ '^[A-Z]{3}$');

create table public.virtual_balance_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  virtual_order_id uuid references public.virtual_orders (id) on delete set null,
  transaction_type text not null check (
    transaction_type in ('purchase', 'refund', 'adjustment')
  ),
  amount_delta numeric(12,2) not null check (amount_delta <> 0),
  balance_after_amount numeric(12,2) not null check (balance_after_amount >= 0),
  currency_code text not null check (currency_code ~ '^[A-Z]{3}$'),
  description text,
  created_at timestamptz not null default timezone('utc', now())
);

create index virtual_balance_transactions_user_id_created_at_idx
on public.virtual_balance_transactions (user_id, created_at desc);

create index virtual_balance_transactions_virtual_order_id_idx
on public.virtual_balance_transactions (virtual_order_id);

alter table public.virtual_balance_transactions enable row level security;

create policy "users can view their own virtual balance transactions"
on public.virtual_balance_transactions
for select
to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "users can create their own virtual orders"
on public.virtual_orders;

drop policy if exists "users can update their own virtual orders"
on public.virtual_orders;

drop policy if exists "users can delete their own virtual orders"
on public.virtual_orders;

drop policy if exists "users can create their own virtual order items"
on public.virtual_order_items;

drop policy if exists "users can update their own virtual order items"
on public.virtual_order_items;

drop policy if exists "users can delete their own virtual order items"
on public.virtual_order_items;

revoke insert, update, delete on public.virtual_orders from authenticated;
revoke insert, update, delete on public.virtual_order_items from authenticated;

revoke insert, update on public.profiles from authenticated;
grant update (username, display_name, avatar_url, bio)
on public.profiles
to authenticated;

grant select on public.virtual_balance_transactions to authenticated;

grant usage on schema public to service_role;
grant select, update on public.profiles to service_role;
grant select on public.products to service_role;
grant select, insert on public.virtual_orders to service_role;
grant select, insert on public.virtual_order_items to service_role;
grant select, insert on public.virtual_balance_transactions to service_role;

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
  v_currency text;
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
        select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at), '[]'::jsonb)
        from public.virtual_order_items item
        where item.virtual_order_id = v_order.id
      ),
      'balance', jsonb_build_object(
        'amount', v_profile.virtual_balance_amount,
        'currency_code', v_profile.virtual_balance_currency
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

  if v_product.price_amount is not null then
    v_unit_price = v_product.price_amount;
    v_price_source = 'imported';
  else
    v_unit_price = p_manual_price_amount;
    v_price_source = 'manual';
  end if;

  v_currency = upper(coalesce(v_product.currency_code, p_manual_currency_code, ''));

  if v_unit_price is null or v_unit_price <= 0 then
    raise exception using
      errcode = 'P0001',
      message = 'A positive manual price is required because this product has no imported price';
  end if;

  if v_currency !~ '^[A-Z]{3}$' then
    raise exception using
      errcode = 'P0001',
      message = 'A valid three-letter currency code is required';
  end if;

  if v_currency <> v_profile.virtual_balance_currency then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Product currency %s does not match balance currency %s',
        v_currency,
        v_profile.virtual_balance_currency
      );
  end if;

  v_total = round(v_unit_price * p_quantity, 2);

  if v_profile.virtual_balance_amount < v_total then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Insufficient virtual balance: available %s %s, required %s %s',
        v_profile.virtual_balance_amount,
        v_profile.virtual_balance_currency,
        v_total,
        v_currency
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
    v_currency,
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
    quantity
  )
  values (
    v_order.id,
    v_product.id,
    v_product.title,
    v_product.image_url,
    v_currency,
    v_unit_price,
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
    v_currency,
    format('Virtual purchase of %s x%s (%s price)', v_product.title, p_quantity, v_price_source)
  );

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'items', (
      select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at), '[]'::jsonb)
      from public.virtual_order_items item
      where item.virtual_order_id = v_order.id
    ),
    'balance', jsonb_build_object(
      'amount', v_balance_after,
      'currency_code', v_currency
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
