alter table public.virtual_balance_transactions
drop constraint virtual_balance_transactions_transaction_type_check;

alter table public.virtual_balance_transactions
add constraint virtual_balance_transactions_transaction_type_check
check (
  transaction_type in (
    'purchase',
    'refund',
    'adjustment',
    'daily_check_in'
  )
);

create table public.daily_check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  claim_date date not null,
  reward_amount numeric(12,2) not null check (reward_amount > 0),
  streak_count integer not null check (streak_count > 0),
  balance_after_amount numeric(12,2) not null
    check (balance_after_amount >= 0),
  claimed_at timestamptz not null default timezone('utc', now()),
  unique (user_id, claim_date)
);

create index daily_check_ins_user_id_claim_date_idx
on public.daily_check_ins (user_id, claim_date desc);

alter table public.daily_check_ins enable row level security;

create policy "users can view their own daily check-ins"
on public.daily_check_ins
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on public.daily_check_ins
from public, anon, authenticated;

grant select on public.daily_check_ins
to authenticated;

create or replace function public.get_daily_check_in_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_today date := (timezone('utc', now()))::date;
  v_profile public.profiles%rowtype;
  v_check_in public.daily_check_ins%rowtype;
  v_streak integer := 0;
  v_reward numeric(12,2) := 100.00;
begin
  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication is required';
  end if;

  select *
  into v_profile
  from public.profiles
  where id = v_user_id;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'WanderCoin wallet was not found';
  end if;

  select *
  into v_check_in
  from public.daily_check_ins
  where user_id = v_user_id
    and claim_date = v_today;

  if found then
    v_streak = v_check_in.streak_count;
  else
    select coalesce(check_in.streak_count, 0)
    into v_streak
    from public.daily_check_ins check_in
    where check_in.user_id = v_user_id
      and check_in.claim_date = v_today - 1;

    v_streak = coalesce(v_streak, 0);
  end if;

  return jsonb_build_object(
    'claimed_today', v_check_in.id is not null,
    'reward_amount', coalesce(v_check_in.reward_amount, v_reward),
    'streak_count', v_streak,
    'claimed_at', v_check_in.claimed_at,
    'balance', jsonb_build_object(
      'amount', v_profile.virtual_balance_amount,
      'currency_code', 'WCN'
    )
  );
end;
$$;

revoke all on function public.get_daily_check_in_status()
from public, anon, authenticated, service_role;

grant execute on function public.get_daily_check_in_status()
to authenticated;

create or replace function public.claim_daily_check_in()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_today date := (timezone('utc', now()))::date;
  v_profile public.profiles%rowtype;
  v_check_in public.daily_check_ins%rowtype;
  v_reward numeric(12,2) := 100.00;
  v_streak integer;
  v_balance_after numeric(12,2);
begin
  if v_user_id is null then
    raise exception using
      errcode = '42501',
      message = 'Authentication is required';
  end if;

  select *
  into v_profile
  from public.profiles
  where id = v_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'WanderCoin wallet was not found';
  end if;

  select *
  into v_check_in
  from public.daily_check_ins
  where user_id = v_user_id
    and claim_date = v_today;

  if found then
    return jsonb_build_object(
      'claimed_today', true,
      'reward_amount', v_check_in.reward_amount,
      'streak_count', v_check_in.streak_count,
      'claimed_at', v_check_in.claimed_at,
      'balance', jsonb_build_object(
        'amount', v_profile.virtual_balance_amount,
        'currency_code', 'WCN'
      )
    );
  end if;

  select coalesce(check_in.streak_count, 0) + 1
  into v_streak
  from public.daily_check_ins check_in
  where check_in.user_id = v_user_id
    and check_in.claim_date = v_today - 1;

  v_streak = coalesce(v_streak, 1);
  v_balance_after = v_profile.virtual_balance_amount + v_reward;

  update public.profiles
  set virtual_balance_amount = v_balance_after
  where id = v_user_id;

  insert into public.daily_check_ins (
    user_id,
    claim_date,
    reward_amount,
    streak_count,
    balance_after_amount
  )
  values (
    v_user_id,
    v_today,
    v_reward,
    v_streak,
    v_balance_after
  )
  returning *
  into v_check_in;

  insert into public.virtual_balance_transactions (
    user_id,
    transaction_type,
    amount_delta,
    balance_after_amount,
    currency_code,
    description
  )
  values (
    v_user_id,
    'daily_check_in',
    v_reward,
    v_balance_after,
    'WCN',
    format('Daily check-in reward (day %s streak)', v_streak)
  );

  return jsonb_build_object(
    'claimed_today', true,
    'reward_amount', v_check_in.reward_amount,
    'streak_count', v_check_in.streak_count,
    'claimed_at', v_check_in.claimed_at,
    'balance', jsonb_build_object(
      'amount', v_balance_after,
      'currency_code', 'WCN'
    )
  );
end;
$$;

revoke all on function public.claim_daily_check_in()
from public, anon, authenticated, service_role;

grant execute on function public.claim_daily_check_in()
to authenticated;
