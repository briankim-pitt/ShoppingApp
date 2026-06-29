# Product Search

Product-name and brand search uses the eBay Browse API.

## Request

`POST /functions/v1/search-products`

```json
{
  "query": "wireless keyboard",
  "limit": 20,
  "marketplace_id": "EBAY_US"
}
```

The endpoint requires an authenticated Supabase user. `query` must contain
2-100 characters, `limit` must be 1-50, and `marketplace_id` must be one of
the eBay marketplaces accepted by the Edge Function.

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
  "corrected_query": null
}
```

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

The Edge Function obtains and caches an eBay application access token. eBay
credentials and tokens remain server-side.
