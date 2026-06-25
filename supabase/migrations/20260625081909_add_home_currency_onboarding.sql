create table public.supported_currencies (
  currency_code text primary key check (currency_code ~ '^[A-Z]{3}$'),
  display_name text not null,
  symbol text not null,
  minor_unit smallint not null default 2 check (minor_unit between 0 and 3),
  sort_order smallint not null default 100,
  is_active boolean not null default true
);

insert into public.supported_currencies (
  currency_code,
  display_name,
  symbol,
  minor_unit,
  sort_order
)
values
  ('USD', 'US Dollar', '$', 2, 10),
  ('JPY', 'Japanese Yen', '¥', 0, 20),
  ('EUR', 'Euro', '€', 2, 30),
  ('GBP', 'British Pound', '£', 2, 40),
  ('CAD', 'Canadian Dollar', 'CA$', 2, 50),
  ('AUD', 'Australian Dollar', 'A$', 2, 60),
  ('NZD', 'New Zealand Dollar', 'NZ$', 2, 70),
  ('KRW', 'South Korean Won', '₩', 0, 80),
  ('SGD', 'Singapore Dollar', 'S$', 2, 90),
  ('CHF', 'Swiss Franc', 'CHF', 2, 100),
  ('CNY', 'Chinese Yuan', 'CN¥', 2, 110),
  ('HKD', 'Hong Kong Dollar', 'HK$', 2, 120);

alter table public.supported_currencies enable row level security;

create policy "supported currencies are publicly readable"
on public.supported_currencies
for select
to anon, authenticated
using (is_active);

grant select on public.supported_currencies to anon, authenticated;

alter table public.profiles
add column home_currency_set_at timestamptz;

update public.profiles profile
set home_currency_set_at = coalesce(
  (
    select min(virtual_order.created_at)
    from public.virtual_orders virtual_order
    where virtual_order.user_id = profile.id
  ),
  timezone('utc', now())
)
where exists (
  select 1
  from public.virtual_orders virtual_order
  where virtual_order.user_id = profile.id
);

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
  v_currency_code text;
begin
  v_currency_code = upper(trim(coalesce(p_currency_code, '')));

  if not exists (
    select 1
    from public.supported_currencies currency
    where currency.currency_code = v_currency_code
      and currency.is_active
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'Unsupported home currency';
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

  if exists (
    select 1
    from public.virtual_orders virtual_order
    where virtual_order.user_id = p_user_id
  ) or exists (
    select 1
    from public.virtual_balance_transactions balance_transaction
    where balance_transaction.user_id = p_user_id
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'Home currency cannot be changed after the first virtual purchase';
  end if;

  update public.profiles
  set
    virtual_balance_currency = v_currency_code,
    home_currency_set_at = timezone('utc', now())
  where id = p_user_id
  returning *
  into v_profile;

  return jsonb_build_object(
    'home_currency', jsonb_build_object(
      'currency_code', v_profile.virtual_balance_currency,
      'selected_at', v_profile.home_currency_set_at
    ),
    'balance', jsonb_build_object(
      'amount', v_profile.virtual_balance_amount,
      'currency_code', v_profile.virtual_balance_currency
    )
  );
end;
$$;

revoke all on function public.set_home_currency(uuid, text)
from public, anon, authenticated;

grant execute on function public.set_home_currency(uuid, text)
to service_role;

create or replace function private.ensure_order_home_currency()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if not exists (
    select 1
    from public.profiles profile
    where profile.id = new.user_id
      and profile.home_currency_set_at is not null
      and profile.virtual_balance_currency = new.currency_code
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'Choose a home currency before placing a virtual order';
  end if;

  return new;
end;
$$;

revoke all on function private.ensure_order_home_currency()
from public, anon, authenticated, service_role;

create trigger virtual_orders_require_home_currency
before insert on public.virtual_orders
for each row
execute function private.ensure_order_home_currency();

grant select on public.supported_currencies to service_role;
