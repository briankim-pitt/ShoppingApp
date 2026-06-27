alter table public.virtual_orders
add column processing_at timestamptz,
add column out_for_delivery_at timestamptz,
add column cancelled_at timestamptz,
add column estimated_delivery_at timestamptz,
add column next_status_at timestamptz;

update public.virtual_orders
set
  processing_at = case
    when status in ('processing', 'shipped', 'out_for_delivery', 'delivered')
      then coalesce(processing_at, placed_at, created_at)
    else processing_at
  end,
  shipped_at = case
    when status in ('shipped', 'out_for_delivery', 'delivered')
      then coalesce(shipped_at, placed_at, created_at)
    else shipped_at
  end,
  out_for_delivery_at = case
    when status in ('out_for_delivery', 'delivered')
      then coalesce(out_for_delivery_at, shipped_at, placed_at, created_at)
    else out_for_delivery_at
  end,
  delivered_at = case
    when status = 'delivered'
      then coalesce(delivered_at, shipped_at, placed_at, created_at)
    else delivered_at
  end,
  cancelled_at = case
    when status = 'cancelled'
      then coalesce(cancelled_at, updated_at, created_at)
    else cancelled_at
  end,
  estimated_delivery_at = case
    when status = 'cancelled' then null
    else coalesce(
      estimated_delivery_at,
      delivered_at,
      placed_at + interval '4 minutes 30 seconds',
      created_at + interval '4 minutes 30 seconds'
    )
  end,
  next_status_at = case status
    when 'ordered' then now() + interval '30 seconds'
    when 'processing' then now() + interval '1 minute'
    when 'shipped' then now() + interval '2 minutes'
    when 'out_for_delivery' then now() + interval '1 minute'
    else null
  end;

create index virtual_orders_due_shipping_status_idx
on public.virtual_orders (next_status_at, id)
where status in ('ordered', 'processing', 'shipped', 'out_for_delivery')
  and next_status_at is not null;

create table public.virtual_order_status_events (
  id bigint generated always as identity primary key,
  virtual_order_id uuid not null
    references public.virtual_orders (id) on delete cascade,
  status text not null check (
    status in (
      'ordered',
      'processing',
      'shipped',
      'out_for_delivery',
      'delivered',
      'cancelled'
    )
  ),
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (virtual_order_id, status)
);

create index virtual_order_status_events_order_occurred_at_idx
on public.virtual_order_status_events (virtual_order_id, occurred_at);

alter table public.virtual_order_status_events enable row level security;

create policy "users can view status events for their own virtual orders"
on public.virtual_order_status_events
for select
to authenticated
using (
  exists (
    select 1
    from public.virtual_orders virtual_order
    where virtual_order.id = virtual_order_status_events.virtual_order_id
      and virtual_order.user_id = (select auth.uid())
  )
);

grant select on public.virtual_order_status_events to authenticated;
grant select, insert on public.virtual_order_status_events to service_role;
grant usage, select
on sequence public.virtual_order_status_events_id_seq
to service_role;
grant update on public.virtual_orders to service_role;

insert into public.virtual_order_status_events (
  virtual_order_id,
  status,
  occurred_at
)
select
  virtual_order.id,
  virtual_order.status,
  case virtual_order.status
    when 'ordered' then coalesce(virtual_order.placed_at, virtual_order.created_at)
    when 'processing' then coalesce(virtual_order.processing_at, virtual_order.updated_at)
    when 'shipped' then coalesce(virtual_order.shipped_at, virtual_order.updated_at)
    when 'out_for_delivery'
      then coalesce(virtual_order.out_for_delivery_at, virtual_order.updated_at)
    when 'delivered' then coalesce(virtual_order.delivered_at, virtual_order.updated_at)
    when 'cancelled' then coalesce(virtual_order.cancelled_at, virtual_order.updated_at)
  end
from public.virtual_orders virtual_order
on conflict (virtual_order_id, status) do nothing;

create or replace function private.prepare_virtual_order_shipping()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_now timestamptz := now();
begin
  if tg_op = 'INSERT' then
    if new.status = 'ordered' then
      new.placed_at = coalesce(new.placed_at, v_now);
      new.estimated_delivery_at = coalesce(
        new.estimated_delivery_at,
        new.placed_at + interval '4 minutes 30 seconds'
      );
      new.next_status_at = coalesce(
        new.next_status_at,
        new.placed_at + interval '30 seconds'
      );
    end if;

    return new;
  end if;

  if new.status is not distinct from old.status then
    return new;
  end if;

  if not (
    (old.status = 'ordered' and new.status in ('processing', 'cancelled'))
    or (old.status = 'processing' and new.status in ('shipped', 'cancelled'))
    or (old.status = 'shipped' and new.status in ('out_for_delivery', 'cancelled'))
    or (old.status = 'out_for_delivery' and new.status in ('delivered', 'cancelled'))
  ) then
    raise exception using
      errcode = 'P0001',
      message = format(
        'Invalid shipping transition from %s to %s',
        old.status,
        new.status
      );
  end if;

  case new.status
    when 'processing' then
      new.processing_at = coalesce(new.processing_at, v_now);
      new.next_status_at = new.processing_at + interval '1 minute';
    when 'shipped' then
      new.shipped_at = coalesce(new.shipped_at, v_now);
      new.next_status_at = new.shipped_at + interval '2 minutes';
    when 'out_for_delivery' then
      new.out_for_delivery_at = coalesce(new.out_for_delivery_at, v_now);
      new.next_status_at = new.out_for_delivery_at + interval '1 minute';
    when 'delivered' then
      new.delivered_at = coalesce(new.delivered_at, v_now);
      new.estimated_delivery_at = new.delivered_at;
      new.next_status_at = null;
    when 'cancelled' then
      new.cancelled_at = coalesce(new.cancelled_at, v_now);
      new.estimated_delivery_at = null;
      new.next_status_at = null;
  end case;

  return new;
end;
$$;

revoke all on function private.prepare_virtual_order_shipping()
from public, anon, authenticated, service_role;

create trigger virtual_orders_prepare_shipping
before insert or update of status on public.virtual_orders
for each row
execute function private.prepare_virtual_order_shipping();

create or replace function private.record_virtual_order_status_event()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_occurred_at timestamptz;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;

  v_occurred_at = case new.status
    when 'ordered' then coalesce(new.placed_at, new.created_at)
    when 'processing' then coalesce(new.processing_at, new.updated_at)
    when 'shipped' then coalesce(new.shipped_at, new.updated_at)
    when 'out_for_delivery' then coalesce(new.out_for_delivery_at, new.updated_at)
    when 'delivered' then coalesce(new.delivered_at, new.updated_at)
    when 'cancelled' then coalesce(new.cancelled_at, new.updated_at)
  end;

  insert into public.virtual_order_status_events (
    virtual_order_id,
    status,
    occurred_at
  )
  values (
    new.id,
    new.status,
    v_occurred_at
  )
  on conflict (virtual_order_id, status) do nothing;

  return new;
end;
$$;

revoke all on function private.record_virtual_order_status_event()
from public, anon, authenticated, service_role;

create trigger virtual_orders_record_status_event
after insert or update of status on public.virtual_orders
for each row
execute function private.record_virtual_order_status_event();

create or replace function public.advance_virtual_order_shipping(
  p_user_id uuid,
  p_order_id uuid,
  p_force boolean default false
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_order public.virtual_orders%rowtype;
  v_previous_status text;
  v_next_status text;
begin
  select *
  into v_order
  from public.virtual_orders
  where id = p_order_id
    and user_id = p_user_id
  for update;

  if not found then
    raise exception using
      errcode = 'P0001',
      message = 'Virtual order was not found';
  end if;

  if v_order.status in ('delivered', 'cancelled') then
    raise exception using
      errcode = 'P0001',
      message = format('Virtual order is already %s', v_order.status);
  end if;

  v_previous_status = v_order.status;

  if not p_force and (
    v_order.next_status_at is null
    or v_order.next_status_at > now()
  ) then
    return jsonb_build_object(
      'order', to_jsonb(v_order),
      'events', (
        select coalesce(
          jsonb_agg(to_jsonb(event) order by event.occurred_at),
          '[]'::jsonb
        )
        from public.virtual_order_status_events event
        where event.virtual_order_id = v_order.id
      ),
      'advanced', false,
      'previous_status', v_previous_status
    );
  end if;

  v_next_status = case v_order.status
    when 'ordered' then 'processing'
    when 'processing' then 'shipped'
    when 'shipped' then 'out_for_delivery'
    when 'out_for_delivery' then 'delivered'
  end;

  update public.virtual_orders
  set status = v_next_status
  where id = v_order.id
  returning *
  into v_order;

  return jsonb_build_object(
    'order', to_jsonb(v_order),
    'events', (
      select coalesce(
        jsonb_agg(to_jsonb(event) order by event.occurred_at),
        '[]'::jsonb
      )
      from public.virtual_order_status_events event
      where event.virtual_order_id = v_order.id
    ),
    'advanced', true,
    'previous_status', v_previous_status
  );
end;
$$;

revoke all on function public.advance_virtual_order_shipping(
  uuid,
  uuid,
  boolean
) from public, anon, authenticated;

grant execute on function public.advance_virtual_order_shipping(
  uuid,
  uuid,
  boolean
) to service_role;

create or replace function public.advance_due_virtual_order_shipping(
  p_limit integer default 100,
  p_now timestamptz default now()
)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_order record;
  v_advanced_count integer := 0;
begin
  if p_limit < 1 or p_limit > 1000 then
    raise exception using
      errcode = 'P0001',
      message = 'Shipping batch limit must be between 1 and 1000';
  end if;

  for v_order in
    select virtual_order.id, virtual_order.user_id
    from public.virtual_orders virtual_order
    where virtual_order.status in (
      'ordered',
      'processing',
      'shipped',
      'out_for_delivery'
    )
      and virtual_order.next_status_at <= p_now
    order by virtual_order.next_status_at, virtual_order.id
    limit p_limit
    for update skip locked
  loop
    perform public.advance_virtual_order_shipping(
      v_order.user_id,
      v_order.id,
      true
    );
    v_advanced_count = v_advanced_count + 1;
  end loop;

  return v_advanced_count;
end;
$$;

revoke all on function public.advance_due_virtual_order_shipping(
  integer,
  timestamptz
) from public, anon, authenticated, service_role;

create extension if not exists pg_cron with schema pg_catalog;

do $$
declare
  v_job_id bigint;
begin
  select jobid
  into v_job_id
  from cron.job
  where jobname = 'advance-virtual-order-shipping';

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'advance-virtual-order-shipping',
    '* * * * *',
    'select public.advance_due_virtual_order_shipping();'
  );
end;
$$;
