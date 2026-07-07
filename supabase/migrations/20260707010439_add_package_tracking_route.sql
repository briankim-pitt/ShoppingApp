alter table public.virtual_orders
add column origin_name text,
add column origin_latitude double precision,
add column origin_longitude double precision,
add column destination_name text,
add column destination_latitude double precision,
add column destination_longitude double precision;

create or replace function private.virtual_order_route(p_order_id uuid)
returns table (
  origin_name text,
  origin_latitude double precision,
  origin_longitude double precision,
  destination_name text,
  destination_latitude double precision,
  destination_longitude double precision
)
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  v_locations constant jsonb := jsonb_build_array(
    jsonb_build_object('name', 'Seattle Fulfillment Center', 'lat', 47.6062, 'lng', -122.3321),
    jsonb_build_object('name', 'Los Angeles Hub', 'lat', 34.0522, 'lng', -118.2437),
    jsonb_build_object('name', 'Chicago Depot', 'lat', 41.8781, 'lng', -87.6298),
    jsonb_build_object('name', 'New York Warehouse', 'lat', 40.7128, 'lng', -74.0060),
    jsonb_build_object('name', 'London Hub', 'lat', 51.5074, 'lng', -0.1278),
    jsonb_build_object('name', 'Berlin Depot', 'lat', 52.5200, 'lng', 13.4050),
    jsonb_build_object('name', 'Tokyo Fulfillment Center', 'lat', 35.6762, 'lng', 139.6503),
    jsonb_build_object('name', 'Sydney Warehouse', 'lat', -33.8688, 'lng', 151.2093)
  );
  v_count constant integer := jsonb_array_length(v_locations);
  v_seed bigint := abs(hashtextextended(p_order_id::text, 0));
  v_origin_index integer := (v_seed % v_count)::integer;
  v_destination_index integer :=
    ((v_seed / v_count + 1 + v_origin_index) % v_count)::integer;
begin
  if v_destination_index = v_origin_index then
    v_destination_index := (v_origin_index + 1) % v_count;
  end if;

  return query select
    v_locations -> v_origin_index ->> 'name',
    (v_locations -> v_origin_index ->> 'lat')::double precision,
    (v_locations -> v_origin_index ->> 'lng')::double precision,
    v_locations -> v_destination_index ->> 'name',
    (v_locations -> v_destination_index ->> 'lat')::double precision,
    (v_locations -> v_destination_index ->> 'lng')::double precision;
end;
$$;

revoke all on function private.virtual_order_route(uuid)
from public, anon, authenticated, service_role;

grant usage on schema private to service_role;

grant execute on function private.virtual_order_route(uuid)
to service_role;

create or replace function private.assign_virtual_order_route()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_route record;
begin
  if new.origin_latitude is not null then
    return new;
  end if;

  select * into v_route from private.virtual_order_route(new.id);

  new.origin_name = v_route.origin_name;
  new.origin_latitude = v_route.origin_latitude;
  new.origin_longitude = v_route.origin_longitude;
  new.destination_name = v_route.destination_name;
  new.destination_latitude = v_route.destination_latitude;
  new.destination_longitude = v_route.destination_longitude;

  return new;
end;
$$;

revoke all on function private.assign_virtual_order_route()
from public, anon, authenticated, service_role;

create trigger virtual_orders_assign_route
before insert on public.virtual_orders
for each row
execute function private.assign_virtual_order_route();

with routes as (
  select
    virtual_order.id,
    route.origin_name,
    route.origin_latitude,
    route.origin_longitude,
    route.destination_name,
    route.destination_latitude,
    route.destination_longitude
  from public.virtual_orders virtual_order
  cross join lateral private.virtual_order_route(virtual_order.id) route
  where virtual_order.origin_latitude is null
)
update public.virtual_orders virtual_order
set
  origin_name = routes.origin_name,
  origin_latitude = routes.origin_latitude,
  origin_longitude = routes.origin_longitude,
  destination_name = routes.destination_name,
  destination_latitude = routes.destination_latitude,
  destination_longitude = routes.destination_longitude
from routes
where virtual_order.id = routes.id;
