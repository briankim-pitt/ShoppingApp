import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const marketplaceSchema = z.enum([
  "EBAY_AT",
  "EBAY_AU",
  "EBAY_BE",
  "EBAY_CA",
  "EBAY_CH",
  "EBAY_DE",
  "EBAY_ES",
  "EBAY_FR",
  "EBAY_GB",
  "EBAY_HK",
  "EBAY_IE",
  "EBAY_IT",
  "EBAY_NL",
  "EBAY_PL",
  "EBAY_SG",
  "EBAY_US",
]);

const requestSchema = z.object({
  query: z.string().trim().min(2).max(100),
  limit: z.number().int().min(1).max(50).default(20),
  marketplace_id: marketplaceSchema.optional(),
  brand: z.string().trim().min(1).max(80).optional(),
  category_id: z.string().trim().regex(/^\d{1,12}$/).optional(),
});

type EbayImage = {
  imageUrl?: string;
};

type EbayPrice = {
  value?: string;
  currency?: string;
};

type EbayItemSummary = {
  itemId?: string;
  title?: string;
  itemWebUrl?: string;
  itemAffiliateWebUrl?: string;
  image?: EbayImage;
  price?: EbayPrice;
  condition?: string;
  buyingOptions?: string[];
  categories?: Array<{
    categoryId?: string;
    categoryName?: string;
  }>;
  seller?: {
    username?: string;
    feedbackPercentage?: string;
    feedbackScore?: number;
  };
  adultOnly?: boolean;
};

type EbaySearchResponse = {
  total?: number;
  itemSummaries?: EbayItemSummary[];
  autoCorrections?: {
    q?: string;
  };
  refinement?: {
    dominantCategoryId?: string;
    aspectDistributions?: Array<{
      localizedAspectName?: string;
      aspectValueDistributions?: Array<{
        localizedAspectValue?: string;
        matchCount?: number;
      }>;
    }>;
  };
};

type BrandRefinement = {
  name: string;
  match_count: number | null;
};

type CachedProduct = {
  canonical_url: string;
  source_domain: string;
  title: string;
  image_url: string | null;
  currency_code: string | null;
  price_amount: number | null;
  wandercoin_price_amount: number | null;
  brand?: string;
  metadata: Record<string, unknown>;
  last_imported_at: string;
};

type SavedProduct = {
  id: string;
  canonical_url: string;
  source_domain: string;
  title: string;
  description: string | null;
  image_url: string | null;
  currency_code: string | null;
  price_amount: number | null;
  wandercoin_price_amount: number | null;
  brand: string | null;
  created_at: string;
  updated_at: string;
  last_imported_at: string;
};

type ProductAdminClient = {
  from: (table: "products") => {
    upsert: (
      rows: CachedProduct[],
      options: {
        onConflict: string;
        ignoreDuplicates: boolean;
        defaultToNull: boolean;
      },
    ) => {
      select: (columns: string) => Promise<{
        data: SavedProduct[] | null;
        error: { message: string } | null;
      }>;
    };
  };
};

type EbayToken = {
  value: string;
  expiresAt: number;
};

let cachedToken: EbayToken | null = null;

function json(body: unknown, status = 200) {
  return Response.json(body, {
    status,
    headers: {
      "cache-control": "no-store",
    },
  });
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Unexpected error";
}

function ebayApiBaseUrl() {
  return Deno.env.get("EBAY_API_BASE_URL") ?? "https://api.ebay.com";
}

function ebayIdentityBaseUrl() {
  return Deno.env.get("EBAY_IDENTITY_BASE_URL") ?? ebayApiBaseUrl();
}

function configuredMarketplace() {
  const configured = Deno.env.get("EBAY_MARKETPLACE_ID") ?? "EBAY_US";
  return marketplaceSchema.parse(configured);
}

function credentials() {
  const clientId = Deno.env.get("EBAY_CLIENT_ID");
  const clientSecret = Deno.env.get("EBAY_CLIENT_SECRET");

  if (!clientId || !clientSecret) {
    throw new Error(
      "eBay search is not configured. Set EBAY_CLIENT_ID and EBAY_CLIENT_SECRET.",
    );
  }

  return { clientId, clientSecret };
}

async function ebayAccessToken() {
  if (cachedToken && cachedToken.expiresAt > Date.now()) {
    return cachedToken.value;
  }

  const { clientId, clientSecret } = credentials();
  const basicCredentials = btoa(`${clientId}:${clientSecret}`);
  const body = new URLSearchParams({
    grant_type: "client_credentials",
    scope: "https://api.ebay.com/oauth/api_scope",
  });

  const response = await fetch(
    `${ebayIdentityBaseUrl()}/identity/v1/oauth2/token`,
    {
      method: "POST",
      headers: {
        authorization: `Basic ${basicCredentials}`,
        "content-type": "application/x-www-form-urlencoded",
      },
      body,
    },
  );

  if (!response.ok) {
    throw new Error(`eBay authentication failed with status ${response.status}`);
  }

  const payload = await response.json() as {
    access_token?: string;
    expires_in?: number;
  };
  if (!payload.access_token) {
    throw new Error("eBay authentication returned no access token");
  }

  const lifetime = Math.max((payload.expires_in ?? 7200) - 60, 60);
  cachedToken = {
    value: payload.access_token,
    expiresAt: Date.now() + lifetime * 1000,
  };
  return cachedToken.value;
}

function canonicalizeEbayUrl(rawUrl: string) {
  const url = new URL(rawUrl);
  url.hash = "";
  url.search = "";
  return url.toString();
}

function normalizedPrice(price: EbayPrice | undefined) {
  if (!price?.value) {
    return null;
  }

  const value = Number(price.value);
  return Number.isFinite(value) && value > 0 ? value : null;
}

function normalizedCurrency(price: EbayPrice | undefined) {
  const currency = price?.currency?.trim().toUpperCase();
  return currency && /^[A-Z]{3}$/.test(currency) ? currency : null;
}

function normalizedImageUrl(image: EbayImage | undefined) {
  const rawUrl = image?.imageUrl?.trim();
  if (!rawUrl) {
    return null;
  }

  try {
    const url = new URL(rawUrl);
    if (url.protocol === "http:") {
      url.protocol = "https:";
    }
    return url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

function brandRefinements(response: EbaySearchResponse): BrandRefinement[] {
  const distribution = response.refinement?.aspectDistributions?.find(
    (aspect) => aspect.localizedAspectName?.toLowerCase() === "brand",
  );

  const brands = (distribution?.aspectValueDistributions ?? [])
    .flatMap((value) => {
      const name = value.localizedAspectValue?.trim();
      if (!name || /^unbranded$/i.test(name)) {
        return [];
      }

      return [{
        name,
        match_count: value.matchCount ?? null,
      }];
    })
    .sort((a, b) => (b.match_count ?? 0) - (a.match_count ?? 0));

  return brands.slice(0, 12);
}

function cachedProduct(
  item: EbayItemSummary,
  query: string,
  brand: string | undefined,
  marketplace: z.infer<typeof marketplaceSchema>,
  fetchedAt: string,
) {
  const rawUrl = item.itemWebUrl ?? item.itemAffiliateWebUrl;
  if (!rawUrl || !item.title?.trim() || !item.itemId || item.adultOnly) {
    return null;
  }

  let canonicalUrl: string;
  try {
    canonicalUrl = canonicalizeEbayUrl(rawUrl);
  } catch {
    return null;
  }

  const currencyCode = normalizedCurrency(item.price);
  const priceAmount = normalizedPrice(item.price);

  return {
    ...brand ? { brand } : {},
    canonical_url: canonicalUrl,
    source_domain: new URL(canonicalUrl).hostname,
    title: item.title.trim(),
    image_url: normalizedImageUrl(item.image),
    currency_code: currencyCode,
    price_amount: priceAmount,
    wandercoin_price_amount: currencyCode === "USD" && priceAmount !== null
      ? Math.ceil(priceAmount)
      : null,
    metadata: {
      provider: "ebay",
      provider_item_id: item.itemId,
      marketplace_id: marketplace,
      condition: item.condition ?? null,
      buying_options: item.buyingOptions ?? [],
      categories: item.categories ?? [],
      seller: item.seller ?? null,
      search_query: query,
      fetched_at: fetchedAt,
    },
    last_imported_at: fetchedAt,
  } satisfies CachedProduct;
}

async function searchEbay(
  query: string,
  limit: number,
  marketplace: z.infer<typeof marketplaceSchema>,
  brand?: string,
  categoryId?: string,
) {
  const token = await ebayAccessToken();
  const url = new URL(
    "/buy/browse/v1/item_summary/search",
    ebayApiBaseUrl(),
  );
  url.searchParams.set("limit", String(limit));
  url.searchParams.set("auto_correct", "KEYWORD");
  // MATCHES is rejected by the Browse API; FULL keeps item summaries in the
  // response when ASPECT_REFINEMENTS is requested.
  url.searchParams.set("fieldgroups", "FULL,ASPECT_REFINEMENTS");

  if (brand && categoryId) {
    // Aspect filters only apply within a category scope.
    url.searchParams.set("q", query);
    url.searchParams.set("category_ids", categoryId);
    url.searchParams.set(
      "aspect_filter",
      `categoryId:${categoryId},Brand:{${brand}}`,
    );
  } else if (brand) {
    const lowercasedQuery = query.toLowerCase();
    const q = lowercasedQuery.includes(brand.toLowerCase())
      ? query
      : `${brand} ${query}`;
    url.searchParams.set("q", q);
  } else {
    url.searchParams.set("q", query);
  }

  const response = await fetch(url, {
    headers: {
      authorization: `Bearer ${token}`,
      "x-ebay-c-marketplace-id": marketplace,
    },
  });

  if (!response.ok) {
    throw new Error(`eBay search failed with status ${response.status}`);
  }

  return await response.json() as EbaySearchResponse;
}

export default {
  fetch: withSupabase({ auth: "user" }, async (request, ctx) => {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    let payload: z.infer<typeof requestSchema>;
    try {
      payload = requestSchema.parse(await request.json());
    } catch (error) {
      return json({ error: errorMessage(error) }, 400);
    }

    let marketplace: z.infer<typeof marketplaceSchema>;
    let searchResponse: EbaySearchResponse;
    try {
      marketplace = payload.marketplace_id ?? configuredMarketplace();
      searchResponse = await searchEbay(
        payload.query,
        payload.limit,
        marketplace,
        payload.brand,
        payload.category_id,
      );
    } catch (error) {
      const message = errorMessage(error);
      const status = message.includes("not configured") ? 503 : 502;
      return json({ error: message }, status);
    }

    const fetchedAt = new Date().toISOString();
    const productsByUrl = new Map<string, CachedProduct>();
    for (const item of searchResponse.itemSummaries ?? []) {
      const product = cachedProduct(
        item,
        payload.query,
        payload.brand,
        marketplace,
        fetchedAt,
      );
      if (product) {
        productsByUrl.set(product.canonical_url, product);
      }
    }

    const brands = brandRefinements(searchResponse);
    const dominantCategoryId = searchResponse.refinement?.dominantCategoryId ??
      null;

    const productRows = [...productsByUrl.values()];
    if (productRows.length === 0) {
      return json({
        products: [],
        total: searchResponse.total ?? 0,
        provider: "ebay",
        marketplace_id: marketplace,
        corrected_query: searchResponse.autoCorrections?.q ?? null,
        brands,
        dominant_category_id: dominantCategoryId,
      });
    }

    const admin = ctx.supabaseAdmin as unknown as ProductAdminClient;
    const { data, error } = await admin
      .from("products")
      .upsert(productRows, {
        onConflict: "canonical_url",
        ignoreDuplicates: false,
        defaultToNull: false,
      })
      .select(
        "id,canonical_url,source_domain,title,description,image_url,currency_code,price_amount,wandercoin_price_amount,brand,created_at,updated_at,last_imported_at",
      );

    if (error) {
      return json({ error: error.message }, 500);
    }

    const savedByUrl = new Map(
      (data ?? []).map((product) => [product.canonical_url, product]),
    );
    const orderedProducts = productRows.flatMap((product) => {
      const saved = savedByUrl.get(product.canonical_url);
      return saved ? [saved] : [];
    });

    return json({
      products: orderedProducts,
      total: searchResponse.total ?? orderedProducts.length,
      provider: "ebay",
      marketplace_id: marketplace,
      corrected_query: searchResponse.autoCorrections?.q ?? null,
      brands,
      dominant_category_id: dominantCategoryId,
    });
  }),
};
