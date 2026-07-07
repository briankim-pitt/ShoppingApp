# Imported Product Catalog

Discover is backed by imported products stored in `public.products`. Rows are
created by the URL importer, the iOS share extension, and the Safari
extension. The app reads catalog data directly from PostgREST; it no longer
calls the eBay-backed `search-products` Edge Function.

## Data Sources

- `public.products`: normalized product rows used by Discover, cart,
  checkout, wishlists, and orders.
- `public.product_brands`: a `security_invoker` view that returns distinct
  non-null product brands with counts:

```json
[
  { "name": "Wooting", "match_count": 12 }
]
```

Authenticated users can select from both the table and the view. Anonymous
users should not be granted access to the brand view.

## Discover Flow

The initial Discover load fetches the latest imported products:

```http
GET /rest/v1/products?select=...&order=last_imported_at.desc&limit=50
```

Search in Products mode filters the imported catalog with case-insensitive
matches on `title` or `brand`. Before sending the PostgREST `or` filter, the
app strips characters that can break filter syntax: `%`, `,`, `(`, `)`, and
`.`.

Brand chips come from `product_brands`, ordered by `match_count` descending.
Tapping a brand opens a brand page backed by:

```http
GET /rest/v1/products?brand=ilike.<brand>&order=last_imported_at.desc&limit=50
```

If the catalog is empty, Discover points users to import products from Safari
or paste a product URL.

## Imports

Product import still uses `supabase/functions/import-product/`. Existing
eBay-cached rows in `products` remain valid catalog content and do not need a
data cleanup.

## Deprecated: eBay Search

`supabase/functions/search-products/` remains in the repo for future use and
manual testing, but the Swift app no longer calls it.

The deprecated endpoint is:

```json
{
  "query": "wireless keyboard",
  "limit": 20,
  "marketplace_id": "EBAY_US",
  "brand": "Wooting",
  "category_id": "33963"
}
```

It requires an authenticated Supabase user. `query` must contain 2-100
characters, `limit` must be 1-50, and `marketplace_id` must be one of the
eBay marketplaces accepted by the Edge Function. Optional `brand` and
`category_id` fields apply eBay-specific filtering.

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
