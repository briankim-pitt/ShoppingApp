import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";
import { createClient } from "npm:@supabase/supabase-js@2.108.2";
import * as cheerio from "npm:cheerio@1.2.0";
import { z } from "npm:zod@4.4.3";

const requestSchema = z.object({
  url: z.string().url(),
});

const blockedHostnames = new Set([
  "localhost",
  "0.0.0.0",
  "127.0.0.1",
  "::1",
]);

type ProductMetadata = {
  canonicalUrl: string;
  sourceUrl: string;
  sourceDomain: string;
  title: string;
  description: string | null;
  imageUrl: string | null;
  currencyCode: string | null;
  priceAmount: number | null;
  rawPayload: Record<string, unknown>;
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
  if (error instanceof Error) {
    return error.message;
  }

  return "Unexpected error";
}

function isPrivateIpv4(hostname: string) {
  const parts = hostname.split(".").map((part) => Number(part));
  if (parts.length !== 4 || parts.some((part) => Number.isNaN(part) || part < 0 || part > 255)) {
    return false;
  }

  return (
    parts[0] === 10 ||
    parts[0] === 127 ||
    (parts[0] === 169 && parts[1] === 254) ||
    (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) ||
    (parts[0] === 192 && parts[1] === 168)
  );
}

function isBlockedHostname(hostname: string) {
  const normalized = hostname.toLowerCase();
  if (blockedHostnames.has(normalized)) {
    return true;
  }

  if (
    normalized.endsWith(".localhost") ||
    normalized.endsWith(".local") ||
    normalized.endsWith(".internal")
  ) {
    return true;
  }

  if (isPrivateIpv4(normalized)) {
    return true;
  }

  if (normalized.includes(":")) {
    return normalized === "::1" || normalized.startsWith("fc") || normalized.startsWith("fd") || normalized.startsWith("fe80:");
  }

  return false;
}

function normalizeUrl(rawUrl: string) {
  const parsed = new URL(rawUrl);
  if (!["http:", "https:"].includes(parsed.protocol)) {
    throw new Error("Only http and https URLs are allowed");
  }

  if (isBlockedHostname(parsed.hostname)) {
    throw new Error("That hostname is not allowed");
  }

  parsed.hash = "";

  const removableParams = ["fbclid", "gclid", "mc_cid", "mc_eid"];
  for (const key of [...parsed.searchParams.keys()]) {
    if (key.toLowerCase().startsWith("utm_") || removableParams.includes(key.toLowerCase())) {
      parsed.searchParams.delete(key);
    }
  }

  if (!parsed.searchParams.toString()) {
    parsed.search = "";
  }

  return parsed.toString();
}

function resolveUrl(rawUrl: string, baseUrl?: string) {
  if (baseUrl) {
    return normalizeUrl(new URL(rawUrl, baseUrl).toString());
  }

  return normalizeUrl(rawUrl);
}

function firstNonEmpty(...values: Array<string | null | undefined>) {
  for (const value of values) {
    if (value && value.trim()) {
      return value.trim();
    }
  }

  return null;
}

function textFromSelector($: cheerio.CheerioAPI, selector: string, attr?: string) {
  const node = $(selector).first();
  if (!node.length) {
    return null;
  }

  const rawValue = attr ? node.attr(attr) : node.text();
  return rawValue?.trim() || null;
}

function normalizeCurrencyCode(value: string | null) {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toUpperCase();
  return /^[A-Z]{3}$/.test(normalized) ? normalized : null;
}

function parsePrice(value: string | null) {
  if (!value) {
    return null;
  }

  const normalized = value.replace(/[^0-9.,-]/g, "").replace(/,/g, "");
  if (!normalized) {
    return null;
  }

  const amount = Number(normalized);
  return Number.isFinite(amount) ? amount : null;
}

function extractMetadata(html: string, sourceUrl: string) {
  const $ = cheerio.load(html);

  const canonicalHref = firstNonEmpty(
    textFromSelector($, 'link[rel="canonical"]', "href"),
    textFromSelector($, 'meta[property="og:url"]', "content"),
    sourceUrl,
  );
  const canonicalUrl = resolveUrl(canonicalHref ?? sourceUrl, sourceUrl);
  const sourceDomain = new URL(canonicalUrl).hostname;

  const title = firstNonEmpty(
    textFromSelector($, 'meta[property="og:title"]', "content"),
    textFromSelector($, "title"),
    textFromSelector($, "h1"),
  );
  if (!title) {
    throw new Error("No product title could be extracted from that page");
  }

  const description = firstNonEmpty(
    textFromSelector($, 'meta[name="description"]', "content"),
    textFromSelector($, 'meta[property="og:description"]', "content"),
  );
  const imageUrl = firstNonEmpty(
    textFromSelector($, 'meta[property="og:image"]', "content"),
    textFromSelector($, 'meta[name="twitter:image"]', "content"),
  );
  const currencyCode = normalizeCurrencyCode(firstNonEmpty(
    textFromSelector($, 'meta[property="product:price:currency"]', "content"),
    textFromSelector($, 'meta[itemprop="priceCurrency"]', "content"),
  ));
  const priceAmount = parsePrice(firstNonEmpty(
    textFromSelector($, 'meta[property="product:price:amount"]', "content"),
    textFromSelector($, 'meta[itemprop="price"]', "content"),
    textFromSelector($, '[data-testid="price"]'),
  ));

  return {
    canonicalUrl,
    sourceUrl,
    sourceDomain,
    title,
    description,
    imageUrl,
    currencyCode,
    priceAmount,
    rawPayload: {
      fetchedAt: new Date().toISOString(),
      title,
      description,
      imageUrl,
      currencyCode,
      priceAmount,
    },
  } satisfies ProductMetadata;
}

async function fetchPage(url: string) {
  const response = await fetch(url, {
    method: "GET",
    redirect: "follow",
    signal: AbortSignal.timeout(8000),
    headers: {
      "accept": "text/html,application/xhtml+xml",
      "user-agent": "ShoppingAppBot/0.1 (+https://shoppingapp.local/import)",
    },
  });

  if (!response.ok) {
    throw new Error(`Could not fetch page: ${response.status}`);
  }

  if (isBlockedHostname(new URL(response.url).hostname)) {
    throw new Error("The final destination hostname is not allowed");
  }

  const contentType = response.headers.get("content-type") ?? "";
  if (!contentType.includes("text/html")) {
    throw new Error("The URL did not return an HTML page");
  }

  return response.text();
}

export default {
  fetch: withSupabase({ auth: "user" }, async (
    request: Request,
    ctx: unknown,
  ) => {
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const userClaims = typeof ctx === "object" && ctx !== null && "userClaims" in ctx
      ? Reflect.get(ctx, "userClaims")
      : null;
    const rawUserId = typeof userClaims === "object" && userClaims !== null && "sub" in userClaims
      ? Reflect.get(userClaims, "sub")
      : null;
    const userId = typeof rawUserId === "string" && rawUserId.length > 0 ? rawUserId : null;
    if (!userId) {
      return json({ error: "Missing authenticated user" }, 401);
    }

    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    if (!serviceRoleKey || !supabaseUrl) {
      return json({ error: "Missing Supabase environment variables" }, 500);
    }

    let payload: z.infer<typeof requestSchema>;
    try {
      payload = requestSchema.parse(await request.json());
    } catch (error) {
      return json({ error: errorMessage(error) }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });
    let sourceUrl = "";

    try {
      sourceUrl = normalizeUrl(payload.url);
      const html = await fetchPage(sourceUrl);
      const metadata = extractMetadata(html, sourceUrl);

      const { data: product, error: productError } = await admin
        .from("products")
        .upsert({
          canonical_url: metadata.canonicalUrl,
          source_domain: metadata.sourceDomain,
          title: metadata.title,
          description: metadata.description,
          image_url: metadata.imageUrl,
          currency_code: metadata.currencyCode,
          price_amount: metadata.priceAmount,
          metadata: metadata.rawPayload,
          last_imported_at: new Date().toISOString(),
        }, {
          onConflict: "canonical_url",
        })
        .select("*")
        .single();

      if (productError) {
        throw productError;
      }

      const { data: productImport, error: importError } = await admin
        .from("product_imports")
        .insert({
          user_id: userId,
          source_url: sourceUrl,
          canonical_url: metadata.canonicalUrl,
          source_domain: metadata.sourceDomain,
          product_id: product.id,
          status: "succeeded",
          raw_payload: {
            ...metadata.rawPayload,
            requestedBy: userId,
          },
        })
        .select("*")
        .single();

      if (importError) {
        throw importError;
      }

      return json({
        product,
        import: productImport,
      }, 201);
    } catch (error) {
      const message = errorMessage(error);

      if (sourceUrl) {
        await admin.from("product_imports").insert({
          user_id: userId,
          source_url: sourceUrl,
          canonical_url: sourceUrl,
          source_domain: new URL(sourceUrl).hostname,
          status: "failed",
          error_message: message,
          raw_payload: {
            requestedBy: userId,
          },
        });
      }

      return json({ error: message }, 400);
    }
  }),
};
