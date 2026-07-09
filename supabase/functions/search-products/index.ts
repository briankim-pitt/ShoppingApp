import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  query: z.string().trim().min(2).max(100),
  limit: z.number().int().min(1).max(50).default(20),
});

const PROVIDER = "serpapi_google_shopping";

// SerpApi only caches identical queries for ~1 hour on their side, so a
// longer TTL here is what actually saves search credits.
const CACHE_TTL_MS = 24 * 60 * 60 * 1000;

const SAVED_PRODUCT_COLUMNS =
  "id,canonical_url,source_domain,title,description,image_url,currency_code,price_amount,wandercoin_price_amount,brand,created_at,updated_at,last_imported_at";

type SerpShoppingResult = {
  position?: number;
  product_id?: string;
  immersive_product_page_token?: string;
  title?: string;
  product_link?: string;
  link?: string;
  source?: string;
  thumbnail?: string;
  price?: string;
  extracted_price?: number;
  rating?: number;
  reviews?: number;
  delivery?: string;
};

type SerpSearchResponse = {
  error?: string;
  shopping_results?: SerpShoppingResult[];
};

type CachedProduct = {
  canonical_url: string;
  source_domain: string;
  title: string;
  image_url: string | null;
  currency_code: string | null;
  price_amount: number | null;
  wandercoin_price_amount: number | null;
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

type SavedProductsResult = Promise<{
  data: SavedProduct[] | null;
  error: { message: string } | null;
}>;

type ProductAdminClient = {
  from: (table: "products") => {
    select: (columns: string) => {
      eq: (column: string, value: string) => {
        eq: (column: string, value: string) => {
          gte: (column: string, value: string) => {
            order: (column: string, options: { ascending: boolean }) => {
              limit: (count: number) => SavedProductsResult;
            };
          };
        };
      };
    };
    upsert: (
      rows: CachedProduct[],
      options: {
        onConflict: string;
        ignoreDuplicates: boolean;
        defaultToNull: boolean;
      },
    ) => {
      select: (columns: string) => SavedProductsResult;
    };
  };
};

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

function serpApiKey() {
  const key = Deno.env.get("SERPAPI_API_KEY");
  if (!key) {
    throw new Error("Product search is not configured. Set SERPAPI_API_KEY.");
  }
  return key;
}

function normalizedImageUrl(rawUrl: string | undefined) {
  const trimmed = rawUrl?.trim();
  if (!trimmed) {
    return null;
  }

  try {
    const url = new URL(trimmed);
    if (url.protocol === "http:") {
      url.protocol = "https:";
    }
    return url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

function normalizedPrice(extractedPrice: number | undefined) {
  return typeof extractedPrice === "number" &&
      Number.isFinite(extractedPrice) && extractedPrice > 0
    ? extractedPrice
    : null;
}

function cachedProduct(
  result: SerpShoppingResult,
  query: string,
  fetchedAt: string,
) {
  const rawUrl = result.product_link ?? result.link;
  const title = result.title?.trim();
  if (!rawUrl || !title) {
    return null;
  }

  let canonicalUrl: URL;
  try {
    canonicalUrl = new URL(rawUrl);
  } catch {
    return null;
  }

  // Results are searched with gl=us, so prices come back in US dollars.
  const priceAmount = normalizedPrice(result.extracted_price);
  const currencyCode = priceAmount !== null ? "USD" : null;

  return {
    canonical_url: canonicalUrl.toString(),
    source_domain: canonicalUrl.hostname,
    title,
    image_url: normalizedImageUrl(result.thumbnail),
    currency_code: currencyCode,
    price_amount: priceAmount,
    wandercoin_price_amount: priceAmount !== null
      ? Math.ceil(priceAmount)
      : null,
    metadata: {
      provider: PROVIDER,
      provider_product_id: result.product_id ?? null,
      immersive_page_token: result.immersive_product_page_token ?? null,
      position: result.position ?? null,
      source: result.source ?? null,
      rating: result.rating ?? null,
      reviews: result.reviews ?? null,
      delivery: result.delivery ?? null,
      search_query: query,
      fetched_at: fetchedAt,
    },
    last_imported_at: fetchedAt,
  } satisfies CachedProduct;
}

async function cachedSearchProducts(
  admin: ProductAdminClient,
  query: string,
  limit: number,
) {
  const freshSince = new Date(Date.now() - CACHE_TTL_MS).toISOString();
  const { data, error } = await admin
    .from("products")
    .select(SAVED_PRODUCT_COLUMNS)
    .eq("metadata->>provider", PROVIDER)
    .eq("metadata->>search_query", query)
    .gte("last_imported_at", freshSince)
    .order("metadata->position", { ascending: true })
    .limit(limit);

  // A cache lookup failure should never block the search itself.
  if (error || !data || data.length === 0) {
    return null;
  }

  return data;
}

async function searchGoogleShopping(query: string) {
  const url = new URL("https://serpapi.com/search");
  url.searchParams.set("engine", "google_shopping");
  url.searchParams.set("q", query);
  url.searchParams.set("gl", "us");
  url.searchParams.set("hl", "en");
  url.searchParams.set("api_key", serpApiKey());

  const response = await fetch(url);
  const payload = await response.json() as SerpSearchResponse;

  if (payload.error) {
    throw new Error(`Google Shopping search failed: ${payload.error}`);
  }

  if (!response.ok) {
    throw new Error(
      `Google Shopping search failed with status ${response.status}`,
    );
  }

  return payload;
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

    const normalizedQuery = payload.query.toLowerCase();
    const admin = ctx.supabaseAdmin as unknown as ProductAdminClient;

    const cachedProducts = await cachedSearchProducts(
      admin,
      normalizedQuery,
      payload.limit,
    );
    if (cachedProducts) {
      return json({
        products: cachedProducts,
        provider: PROVIDER,
        cached: true,
      });
    }

    let searchResponse: SerpSearchResponse;
    try {
      searchResponse = await searchGoogleShopping(payload.query);
    } catch (error) {
      const message = errorMessage(error);
      const status = message.includes("not configured") ? 503 : 502;
      return json({ error: message }, status);
    }

    const fetchedAt = new Date().toISOString();
    const productsByUrl = new Map<string, CachedProduct>();
    for (const result of searchResponse.shopping_results ?? []) {
      if (productsByUrl.size >= payload.limit) {
        break;
      }

      const product = cachedProduct(result, normalizedQuery, fetchedAt);
      if (product) {
        productsByUrl.set(product.canonical_url, product);
      }
    }

    const productRows = [...productsByUrl.values()];
    if (productRows.length === 0) {
      return json({
        products: [],
        provider: PROVIDER,
        cached: false,
      });
    }

    const { data, error } = await admin
      .from("products")
      .upsert(productRows, {
        onConflict: "canonical_url",
        ignoreDuplicates: false,
        defaultToNull: false,
      })
      .select(SAVED_PRODUCT_COLUMNS);

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
      provider: PROVIDER,
      cached: false,
    });
  }),
};
