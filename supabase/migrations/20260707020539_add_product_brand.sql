alter table public.products
add column brand text;

create index products_brand_idx on public.products (lower(brand));
