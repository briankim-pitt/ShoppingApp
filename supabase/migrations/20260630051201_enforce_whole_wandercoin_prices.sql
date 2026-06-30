update public.products
set wandercoin_price_amount = ceil(wandercoin_price_amount)
where wandercoin_price_amount is not null
  and wandercoin_price_amount <> trunc(wandercoin_price_amount);

alter table public.products
add constraint products_wandercoin_price_amount_whole
check (
  wandercoin_price_amount is null
  or wandercoin_price_amount = trunc(wandercoin_price_amount)
);
