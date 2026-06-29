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
  v_currency text;
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
      bool_or(item.quantity is null or item.quantity < 1 or item.quantity > 99)
    into
      v_product_count,
      v_unique_product_count,
      v_has_missing_fields,
      v_has_invalid_quantity
    from jsonb_to_recordset(p_items) as item(
      product_id uuid,
      quantity integer,
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
        'currency_code', v_profile.virtual_balance_currency
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
      manual_price_amount numeric
    )
    join public.products product
      on product.id = item.product_id
    where coalesce(product.price_amount, item.manual_price_amount) is null
      or coalesce(product.price_amount, item.manual_price_amount) <= 0
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'A positive manual price is required for every product without an imported price';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as item(
      product_id uuid,
      manual_currency_code text
    )
    join public.products product
      on product.id = item.product_id
    where upper(
      coalesce(product.currency_code, item.manual_currency_code, '')
    ) !~ '^[A-Z]{3}$'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'A valid three-letter currency code is required for every product';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as item(
      product_id uuid,
      manual_currency_code text
    )
    join public.products product
      on product.id = item.product_id
    where upper(
      coalesce(product.currency_code, item.manual_currency_code, '')
    ) <> v_profile.virtual_balance_currency
  ) then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Every product must use the balance currency %s',
        v_profile.virtual_balance_currency
      );
  end if;

  select
    round(
      sum(
        coalesce(product.price_amount, item.manual_price_amount)
        * item.quantity
      ),
      2
    ),
    min(
      upper(coalesce(product.currency_code, item.manual_currency_code))
    )
  into v_total, v_currency
  from jsonb_to_recordset(p_items) as item(
    product_id uuid,
    quantity integer,
    manual_price_amount numeric,
    manual_currency_code text
  )
  join public.products product
    on product.id = item.product_id;

  if v_total is null or v_total <= 0 or v_total > 9999999999.99 then
    raise exception using
      errcode = 'P0001',
      message = 'Cart total is outside the supported range';
  end if;

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
  select
    v_order.id,
    item.product_id,
    product.title,
    product.image_url,
    upper(coalesce(product.currency_code, item.manual_currency_code)),
    coalesce(product.price_amount, item.manual_price_amount),
    item.quantity
  from jsonb_to_recordset(p_items) as item(
    product_id uuid,
    quantity integer,
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
    v_currency,
    format('Virtual cart purchase of %s products', v_item_count)
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
      'currency_code', v_currency
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
