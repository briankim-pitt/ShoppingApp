import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { z } from "zod";

const requestSchema = z.object({
  product_id: z.string().uuid(),
});

type ProductRow = {
  id: string;
  image_url: string | null;
  metadata: Record<string, unknown> | null;
};

type ProductAdminClient = {
  from: (table: "products") => {
    select: (columns: string) => {
      eq: (column: string, value: string) => {
        maybeSingle: () => Promise<{
          data: ProductRow | null;
          error: { message: string } | null;
        }>;
      };
    };
    update: (values: { metadata: Record<string, unknown> }) => {
      eq: (column: string, value: string) => Promise<{
        error: { message: string } | null;
      }>;
    };
  };
};

type ImmersiveProductResponse = {
  error?: string;
  product_results?: {
    thumbnails?: string[];
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
    throw new Error("Hero images are not configured. Set SERPAPI_API_KEY.");
  }
  return key;
}

function normalizedImageUrl(rawUrl: unknown) {
  if (typeof rawUrl !== "string" || !rawUrl.trim()) {
    return null;
  }

  try {
    const url = new URL(rawUrl.trim());
    if (url.protocol === "http:") {
      url.protocol = "https:";
    }
    return url.protocol === "https:" ? url.toString() : null;
  } catch {
    return null;
  }
}

async function fetchHeroImage(pageToken: string) {
  const url = new URL("https://serpapi.com/search");
  url.searchParams.set("engine", "google_immersive_product");
  url.searchParams.set("page_token", pageToken);
  url.searchParams.set("api_key", serpApiKey());

  const response = await fetch(url);
  const payload = await response.json() as ImmersiveProductResponse;

  if (payload.error) {
    throw new Error(payload.error);
  }

  if (!response.ok) {
    throw new Error(`Hero image lookup failed with status ${response.status}`);
  }

  // The immersive endpoint returns full-size thumbnails; the first is the
  // primary product shot.
  for (const candidate of payload.product_results?.thumbnails ?? []) {
    const url = normalizedImageUrl(candidate);
    if (url) {
      return url;
    }
  }

  return null;
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

    const admin = ctx.supabaseAdmin as unknown as ProductAdminClient;
    const { data: product, error } = await admin
      .from("products")
      .select("id,image_url,metadata")
      .eq("id", payload.product_id)
      .maybeSingle();

    if (error) {
      return json({ error: error.message }, 500);
    }

    if (!product) {
      return json({ error: "Product not found" }, 404);
    }

    const metadata = product.metadata ?? {};

    // Already upgraded: return the cached hi-res URL for free.
    const cached = normalizedImageUrl(metadata.hero_image_url);
    if (cached) {
      return json({ hero_image_url: cached, cached: true });
    }

    // Products without an immersive token (e.g. Safari imports) have no
    // hi-res source; the client keeps showing its thumbnail.
    const pageToken = metadata.immersive_page_token;
    if (typeof pageToken !== "string" || !pageToken) {
      return json({ hero_image_url: null, cached: false });
    }

    let heroImageURL: string | null;
    try {
      heroImageURL = await fetchHeroImage(pageToken);
    } catch {
      // Tokens expire; leave the thumbnail in place without caching so a
      // later search can refresh the token and retry.
      return json({ hero_image_url: null, cached: false });
    }

    if (!heroImageURL) {
      return json({ hero_image_url: null, cached: false });
    }

    const { error: updateError } = await admin
      .from("products")
      .update({
        metadata: {
          ...metadata,
          hero_image_url: heroImageURL,
          hero_image_fetched_at: new Date().toISOString(),
        },
      })
      .eq("id", product.id);

    if (updateError) {
      return json({ error: updateError.message }, 500);
    }

    return json({ hero_image_url: heroImageURL, cached: false });
  }),
};
