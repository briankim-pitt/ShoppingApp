create extension if not exists pg_trgm with schema extensions;

create index products_title_trgm_idx
on public.products
using gin (title extensions.gin_trgm_ops);

create index products_last_imported_at_idx
on public.products (last_imported_at desc);

create view public.product_brands
with (security_invoker = true) as
select
  brand as name,
  count(*)::integer as match_count
from public.products
where brand is not null
group by brand;

grant select on public.product_brands to authenticated;
