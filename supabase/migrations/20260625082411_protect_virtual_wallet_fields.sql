revoke select on public.profiles from authenticated;

grant select (
  id,
  username,
  display_name,
  avatar_url,
  bio,
  budget_points,
  created_at,
  updated_at
)
on public.profiles
to authenticated;

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
      'currency_code', profile.virtual_balance_currency
    ),
    'home_currency_selected', profile.home_currency_set_at is not null,
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
