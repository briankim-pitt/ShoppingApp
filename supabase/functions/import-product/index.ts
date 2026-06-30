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

function valueFromSelector($: cheerio.CheerioAPI, selector: string) {
  const node = $(selector).first();
  if (!node.length) {
    return null;
  }

  return firstNonEmpty(
    node.attr("content"),
    node.attr("value"),
    node.attr("data-price"),
    node.attr("data-product-price"),
    node.text(),
  );
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

  let normalized = value
    .replace(/[\s\u00a0\u202f']/g, "")
    .replace(/[^0-9.,-]/g, "");
  if (!normalized || normalized.startsWith("-")) {
    return null;
  }

  const lastComma = normalized.lastIndexOf(",");
  const lastDot = normalized.lastIndexOf(".");
  if (lastComma >= 0 && lastDot >= 0) {
    const decimalSeparator = lastComma > lastDot ? "," : ".";
    const thousandsSeparator = decimalSeparator === "," ? "." : ",";
    normalized = normalized.replaceAll(thousandsSeparator, "");
    normalized = normalized.replace(decimalSeparator, ".");
  } else if (lastComma >= 0) {
    const digitsAfterComma = normalized.length - lastComma - 1;
    normalized = digitsAfterComma > 0 && digitsAfterComma <= 2
      ? normalized.replace(",", ".")
      : normalized.replaceAll(",", "");
  } else if (lastDot >= 0) {
    const digitsAfterDot = normalized.length - lastDot - 1;
    if (digitsAfterDot === 3 && normalized.indexOf(".") === lastDot) {
      normalized = normalized.replace(".", "");
    }
  }

  const amount = Number(normalized);
  return Number.isFinite(amount) && amount >= 0 ? amount : null;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function stringValue(value: unknown) {
  if (typeof value === "string" || typeof value === "number") {
    return String(value);
  }

  return null;
}

function hasJsonLdType(value: unknown, expected: string) {
  const types = Array.isArray(value) ? value : [value];
  return types.some((type) =>
    typeof type === "string" && type.toLowerCase() === expected.toLowerCase()
  );
}

function collectJsonLdObjects(value: unknown, objects: Record<string, unknown>[] = []) {
  if (Array.isArray(value)) {
    for (const item of value) {
      collectJsonLdObjects(item, objects);
    }
    return objects;
  }

  const record = asRecord(value);
  if (!record) {
    return objects;
  }

  objects.push(record);
  if ("@graph" in record) {
    collectJsonLdObjects(record["@graph"], objects);
  }

  return objects;
}

function extractJsonLdOffer($: cheerio.CheerioAPI) {
  const objects: Record<string, unknown>[] = [];

  $('script[type="application/ld+json"]').each((_, element) => {
    const raw = $(element).text().trim();
    if (!raw) {
      return;
    }

    try {
      collectJsonLdObjects(JSON.parse(raw), objects);
    } catch {
      // Invalid JSON-LD should not prevent the remaining metadata fallbacks.
    }
  });

  const products = objects.filter((object) => hasJsonLdType(object["@type"], "Product"));
  for (const product of products) {
    const offers = Array.isArray(product.offers) ? product.offers : [product.offers];
    for (const rawOffer of offers) {
      const offer = asRecord(rawOffer);
      if (!offer) {
        continue;
      }

      const priceSpecification = asRecord(offer.priceSpecification);
      const price = firstNonEmpty(
        stringValue(offer.price),
        stringValue(offer.lowPrice),
        stringValue(priceSpecification?.price),
      );
      const currency = firstNonEmpty(
        stringValue(offer.priceCurrency),
        stringValue(priceSpecification?.priceCurrency),
      );
      if (price) {
        return { price, currency };
      }
    }
  }

  return { price: null, currency: null };
}

function inferCurrencyCode(rawPrice: string | null, sourceUrl: string) {
  if (!rawPrice) {
    return null;
  }

  if (rawPrice.includes("€")) return "EUR";
  if (rawPrice.includes("£")) return "GBP";
  if (rawPrice.includes("₩")) return "KRW";
  if (rawPrice.includes("₹")) return "INR";
  if (rawPrice.includes("¥") || rawPrice.includes("￥")) return "JPY";
  if (/\bCA?\$/i.test(rawPrice)) return "CAD";
  if (/\bAU?\$/i.test(rawPrice)) return "AUD";
  if (rawPrice.includes("$")) {
    const hostname = new URL(sourceUrl).hostname.toLowerCase();
    if (hostname.endsWith(".ca")) return "CAD";
    if (hostname.endsWith(".com.au") || hostname.endsWith(".au")) return "AUD";
    if (hostname.endsWith(".co.nz") || hostname.endsWith(".nz")) return "NZD";
    if (hostname.endsWith(".com.sg") || hostname.endsWith(".sg")) return "SGD";
    return "USD";
  }

  return null;
}

function extractMetadata(html: string, sourceUrl: string) {
  const $ = cheerio.load(html);
  const jsonLdOffer = extractJsonLdOffer($);

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
  const rawPrice = firstNonEmpty(
    jsonLdOffer.price,
    textFromSelector($, 'meta[property="product:price:amount"]', "content"),
    textFromSelector($, 'meta[property="og:price:amount"]', "content"),
    valueFromSelector($, '[itemprop="price"]'),
    valueFromSelector($, "[data-product-price]"),
    valueFromSelector($, "[data-price]"),
    valueFromSelector($, '[data-testid*="price" i]'),
  );
  const currencyCode = normalizeCurrencyCode(firstNonEmpty(
    jsonLdOffer.currency,
    textFromSelector($, 'meta[property="product:price:currency"]', "content"),
    textFromSelector($, 'meta[property="og:price:currency"]', "content"),
    valueFromSelector($, '[itemprop="priceCurrency"]'),
    inferCurrencyCode(rawPrice, sourceUrl),
  ));
  const priceAmount = parsePrice(rawPrice);

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
    const rawUserId = typeof userClaims === "object" && userClaims !== null && "id" in userClaims
      ? Reflect.get(userClaims, "id")
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
          wandercoin_price_amount: metadata.currencyCode === "USD" &&
              metadata.priceAmount !== null
            ? Math.ceil(metadata.priceAmount)
            : null,
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
