# Product Search

Product-name and brand search uses the eBay Browse API.

## Request

`POST /functions/v1/search-products`

```json
{
  "query": "wireless keyboard",
  "limit": 20,
  "marketplace_id": "EBAY_US",
  "brand": "Wooting",
  "category_id": "33963"
}
```

The endpoint requires an authenticated Supabase user. `query` must contain
2-100 characters, `limit` must be 1-50, and `marketplace_id` must be one of
the eBay marketplaces accepted by the Edge Function.

`brand` and `category_id` are optional. When both are present, results are
restricted with an eBay `aspect_filter` scoped to that category. With only
`brand`, the brand is prepended to the query keywords. `category_id` must be
a numeric eBay category id, normally the `dominant_category_id` from a prior
response.

The response contains normalized `Product` records:

```json
{
  "products": [
    {
      "id": "bae57acd-a9c7-4acc-8779-6172c4bcc2b5",
      "canonical_url": "https://www.ebay.com/itm/100000000001",
      "source_domain": "www.ebay.com",
      "title": "Wireless Keyboard",
      "description": null,
      "image_url": "https://i.ebayimg.com/images/example.jpg",
      "currency_code": "USD",
      "price_amount": 79.99,
      "wandercoin_price_amount": 79.99
    }
  ],
  "total": 1000,
  "provider": "ebay",
  "marketplace_id": "EBAY_US",
  "corrected_query": null,
  "brands": [
    { "name": "Logitech", "match_count": 240 }
  ],
  "dominant_category_id": "33963"
}
```

`brands` lists up to 12 brand refinements from eBay's aspect distributions
for the search, sorted by match count ("Unbranded" is dropped). Products
cached during a brand-filtered search are stored with their `brand` so the
catalog accumulates brand metadata over time.

Results are cached in `public.products`, allowing the existing cart and
checkout flow to use them without another import step. Adult-only results are
discarded. URL query parameters are removed before caching to prevent duplicate
rows for tracking variations of the same listing.

## eBay Credentials

Create Production application keys in the eBay Developer Program. Use the
App ID as `EBAY_CLIENT_ID` and the Cert ID as `EBAY_CLIENT_SECRET`.

For local development:

```bash
cp supabase/.env.example supabase/.env.local
npx supabase functions serve search-products \
  --env-file supabase/.env.local
```

For the hosted Supabase project:

```bash
npx supabase secrets set \
  EBAY_CLIENT_ID=your-production-app-id \
  EBAY_CLIENT_SECRET=your-production-cert-id \
  EBAY_MARKETPLACE_ID=EBAY_US

npx supabase functions deploy search-products
```

Do not put eBay credentials in the Swift app or commit `.env.local`.

## Marketplace And WanderCoin Pricing

Search defaults to `EBAY_US`. USD prices are copied to
`wandercoin_price_amount` at the fixed rate of one USD to one WanderCoin.
The original `price_amount` and `currency_code` remain unchanged as source
metadata. Non-USD listings do not receive an automatic coin price and require
a manual WanderCoin amount before checkout.

## Swift Flow

The Search tab has two modes:

- `Products`: search eBay by product or brand and add a result to the cart.
- `URL`: use the existing page importer.

Each product search surfaces a "Shop by Brand" chip carousel built from the
`brands` refinements. Tapping a chip pushes a brand page that browses
products for that brand (filtered through `brand` + `dominant_category_id`).
Product cards show the brand name when the catalog knows it.

The Edge Function obtains and caches an eBay application access token. eBay
credentials and tokens remain server-side.
