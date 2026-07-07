# Execution Plan: Imported-Products Catalog (Replace eBay Discover)

Goal: the Discover page and product catalog must be backed by **imported
products** (rows in `public.products`, created via the URL importer, share
extension, and Safari extension) instead of live eBay search. Searching,
brand chips, and brand pages all read from our own database. The eBay-backed
`search-products` edge function stays in the repo but the app stops calling
it.

This plan is prescriptive. Follow the phases in order, read every file in
each "Read first" list before editing, and match the surrounding code style
exactly.

## Ground rules

- iOS 26+, Swift 6 strict concurrency, SwiftUI. Review new SwiftUI code with
  the `swiftui-pro` skill before finishing.
- Reads go straight to PostgREST from the app (like
  `Shopping/Shopping/Features/Orders/SupabaseOrdersService.swift` does) —
  RLS policy "signed in users can browse imported products" already grants
  authenticated select on `products`. Do NOT build a new edge function.
- Do not delete or modify `supabase/functions/search-products/` or
  `supabase/functions/import-product/` — imports still power the catalog.
- Do not touch `worker/`, `QueueMe/`, cart/checkout/wishlist/orders code.
  They already operate on `Product` and are unaffected.
- Existing eBay-cached rows in `products` are legitimate catalog content;
  no data migration or cleanup is needed.

## Target behavior

| Surface | Old (eBay) | New (imported catalog) |
| --- | --- | --- |
| Discover initial load | eBay query "iphone" | Latest imports, `last_imported_at` desc, limit 50 |
| Search bar (Products mode) | eBay keyword search | Case-insensitive match on title OR brand in `products` |
| Category chips (All/Fashion/…) | Canned eBay queries | **Removed entirely** |
| "Shop by Brand" chips | eBay aspect refinements | Distinct `products.brand` values with counts (DB view) |
| Brand page | eBay aspect-filtered search | `products` filtered by brand |
| "Showing results for…" (corrected query) | eBay auto-correct | Removed |
| Empty results | "No Results" | Same, plus empty-catalog state pointing at the URL importer |

---

## Phase 1 — Database migration

**Read first:** `supabase/migrations/20260707020539_add_product_brand.sql`
and the `products` RLS grants in
`supabase/migrations/20260624070412_initial_schema.sql`.

Create `supabase/migrations/<timestamp>_add_catalog_browsing.sql` with the
timestamp from `date -u +%Y%m%d%H%M%S`. Contents:

```sql
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
```

Notes:
- Column aliases `name` / `match_count` are deliberate: the existing Swift
  `ProductBrand` model decodes those keys unchanged.
- `security_invoker = true` makes the view respect the `products` RLS
  policy. Do not grant to `anon`.

**Verify:** `npx supabase migration up`, then with the local anon key +
a signed-in user token:
`GET http://127.0.0.1:54321/rest/v1/product_brands?select=*` returns
`[{"name":...,"match_count":...}]` rows (local DB has imported test rows
from earlier sessions).

---

## Phase 2 — Swift service layer

**Read first:**
`Shopping/Shopping/Features/Search/ProductSearchServing.swift`,
`SupabaseProductSearchService.swift`, `UnavailableProductSearchService.swift`,
`Shopping/Shopping/Features/Orders/SupabaseOrdersService.swift` (query
style), `Shopping/Shopping/Core/Models/ProductBrand.swift`,
`Shopping/Shopping/Core/Config/LiveDependencies.swift`,
`Shopping/Shopping/App/AppModel.swift`.

1. **Delete** these files (their replacements follow):
   - `Features/Search/ProductSearchServing.swift`
   - `Features/Search/SupabaseProductSearchService.swift`
   - `Features/Search/UnavailableProductSearchService.swift`
   - `Core/Models/ProductSearchResponse.swift`
   - `ShoppingTests/ProductSearchBrandTests.swift`
   - `ShoppingTests/ProductSearchCategoryTests.swift`

2. **New `Features/Search/CatalogServing.swift`:**

   ```swift
   protocol CatalogServing: Sendable {
       func browseProducts() async throws -> [Product]
       func searchProducts(query: String) async throws -> [Product]
       func products(forBrand brand: String) async throws -> [Product]
       func listBrands() async throws -> [ProductBrand]
   }
   ```

3. **New `Features/Search/SupabaseCatalogService.swift`.** Use one shared
   column list constant:

   ```
   id, canonical_url, source_domain, title, description, brand, image_url,
   currency_code, price_amount, wandercoin_price_amount, created_at,
   updated_at, last_imported_at
   ```

   - `browseProducts()`: `.from("products").select(columns)
     .order("last_imported_at", ascending: false).limit(50)`
   - `searchProducts(query:)`: sanitize the query first — remove the
     characters `%`, `,`, `(`, `)`, `.` and trim whitespace; if the result
     is empty return `[]` without a request. Then:
     `.or("title.ilike.%\(sanitized)%,brand.ilike.%\(sanitized)%")`
     ordered by `last_imported_at` desc, limit 50. (Sanitizing prevents the
     query text from breaking PostgREST `or=` filter syntax.)
   - `products(forBrand:)`: `.ilike("brand", pattern: brand)` — `ilike`
     with no wildcards is a case-insensitive exact match — ordered by
     `last_imported_at` desc, limit 50.
   - `listBrands()`: `.from("product_brands").select()
     .order("match_count", ascending: false).limit(20)` → `[ProductBrand]`.

4. **New `Features/Search/UnavailableCatalogService.swift`** — all four
   methods `throw ConfigurationError.missingSupabaseURL` (mirror the old
   Unavailable service).

5. **`LiveDependencies.swift` / `AppModel.swift`:** rename the
   `productSearchService` dependency to `catalogService: any CatalogServing`
   everywhere (property, init parameter, `live()`, the Unavailable fallback
   branch). Replace `AppModel.searchProducts(query:brand:categoryID:)` with
   four pass-throughs matching the protocol:
   `browseProducts()`, `searchProducts(query:)`, `products(forBrand:)`,
   `listBrands()`.

6. **`PreviewSupport/PreviewData.swift`:** replace
   `PreviewProductSearchService` with `PreviewCatalogService: CatalogServing`
   returning `[PreviewData.product]` for the three product methods and
   `[ProductBrand(name: "Wooting", matchCount: 12), ProductBrand(name:
   "Keychron", matchCount: 8)]` for `listBrands()`. Update the AppModel
   construction site(s) in that file for the renamed parameter.

7. **`Core/Models/ProductBrand.swift`:** unchanged. Add
   `ShoppingTests/ProductBrandDecodingTests.swift` (Swift Testing style —
   see `ShoppingTests/ProductSearchBrandTests.swift` before deleting it)
   asserting that `[{"name":"Wooting","match_count":12}]` decodes via
   `JSONDecoder.supabase` and that a null `match_count` decodes to nil.

**Verify:** project builds:
`xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping
-destination 'generic/platform=iOS Simulator' build -quiet` (zero new
warnings).

---

## Phase 3 — Discover UI rework

**Read first:** `Features/Search/SearchView.swift`,
`SearchViewModel.swift`, `DiscoverProductsContent.swift`,
`BrandChipCarousel.swift`, `BrandChip.swift`, `BrandSelection.swift`,
`BrandProductsView.swift`, `BrandProductsViewModel.swift`,
`DiscoverSearchHeader.swift`, `SearchErrorView.swift`,
`Core/Design/BrandedActionEmptyState.swift` (reuse if it fits the
empty-catalog CTA).

1. **Delete:** `ProductSearchCategory.swift`,
   `ProductCategoryCarousel.swift`, `ProductCategoryChip.swift`, and
   `BrandSelection.swift` (brand pages now navigate on `ProductBrand`,
   which is already `Hashable`).

2. **`SearchViewModel.swift`:**
   - Remove `selectedCategory`, `correctedQuery`, `dominantCategoryID`,
     `searchProducts(in:using:)`, and `brandSelection(for:)`.
   - `loadInitialProducts(using:)` now calls a new
     `loadCatalog(using:)` which concurrently fetches
     `appModel.browseProducts()` → `products` and `appModel.listBrands()`
     → `brands` (use `async let`). Brand-list failures must not fail the
     whole page: `brands = (try? await ...) ?? []`.
   - `searchProducts(using:)` keeps its guard (`trimmedProductQuery.count
     >= 2`, not already searching) and sets
     `products = try await appModel.searchProducts(query: trimmedProductQuery)`.
     Keep `hasSearchedProducts` / `isSearchingProducts` / `errorMessage`
     behavior identical.
   - Add `func resetToCatalog(using appModel: AppModel) async` that clears
     `productQuery`/`hasSearchedProducts` and reloads the catalog (used by
     pull-to-refresh if present and after an import succeeds — check
     `DiscoverURLImportContent.swift` for an import-success hook; if none
     exists, skip that part).
   - Keep `popularProducts` / `recommendedProducts` but they now slice the
     catalog: rename to `featuredProducts` (first 6) and
     `latestProducts` (rest) only if the rename stays mechanical;
     otherwise keep the old names and just retitle the sections in the view.

3. **`DiscoverProductsContent.swift`:**
   - Remove the `ProductCategoryCarousel` and the `correctedQuery` label,
     and the `selectCategory` closure parameter (also drop it from
     `SearchView`).
   - Keep the brand carousel, but `BrandChipCarousel` now takes only
     `brands: [ProductBrand]` and each chip is
     `NavigationLink(value: brand)`.
   - Section titles: first section "Fresh Imports", second "More from the
     Catalog".
   - Empty catalog state (no search, no products, no error):
     `ContentUnavailableView` titled "Catalog is Empty" with description
     "Import products from Safari or paste a product URL to build the
     catalog." and a button that sets `viewModel.mode = .url`.

4. **`SearchView.swift`:** update `.navigationDestination(for:
   BrandSelection.self)` → `for: ProductBrand.self`, passing the brand into
   `BrandProductsView(brand:transitionNamespace:)`. Remove
   `searchCategory(_:)`.

5. **`BrandProductsView.swift` / `BrandProductsViewModel.swift`:** replace
   `selection: BrandSelection` with `let brand: ProductBrand`; the view
   model loads via `appModel.products(forBrand: brand.name)`. Page title:
   `.appPageTitle(verbatim: brand.name)`. Keep loading/error/empty states
   as they are.

6. **`DiscoverSearchHeader.swift`:** read it; only change things if it
   references categories or corrected queries (it likely doesn't).

**Verify:** build again, then run the full suite:
`xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping
-destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -quiet`.
Run the swiftui-pro review over changed SwiftUI files and fix real findings.

---

## Phase 4 — Docs

- Rewrite `docs/PRODUCT_SEARCH.md` as the catalog doc: Discover reads
  imported products directly from PostgREST (`products`,
  `product_brands` view), search is `ilike` on title/brand, brand chips
  come from the view. Add a short "Deprecated: eBay search" section noting
  `search-products` still exists but the app no longer calls it (keep the
  eBay credential instructions under that heading for future use).
- Update the Bruno note only if `bruno/tests/Search Products.yml` docs
  claim the app uses it; mark it deprecated in its `docs:` field.

---

## Completion checklist

- [ ] Migration applies via `npx supabase migration up`; `product_brands`
      view readable by an authenticated user, not by anon.
- [ ] App has zero references to `ProductSearchResponse`,
      `ProductSearchCategory`, `BrandSelection`, or
      `SupabaseProductSearchService` (`grep -rn` in `Shopping/Shopping`).
- [ ] Discover loads latest imports, search filters by title/brand, brand
      chips navigate to DB-backed brand pages.
- [ ] Empty-catalog state offers the URL-import path.
- [ ] Build clean, full test suite green (including new
      `ProductBrandDecodingTests`), swiftui-pro review done.
- [ ] Docs updated; `search-products` function untouched and marked
      deprecated in docs.
