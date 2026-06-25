import * as cheerio from "cheerio";

export type ScrapedProduct = {
  title: string | null;
  description: string | null;
  imageUrl: string | null;
  priceAmount: number | null;
  currencyCode: string | null;
};

function firstNonEmpty(...values: Array<string | null | undefined>) {
  for (const value of values) {
    if (value && value.trim()) {
      return value.trim();
    }
  }

  return null;
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
      // Ignore malformed structured data and continue with HTML fallbacks.
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

function normalizeCurrencyCode(value: string | null) {
  if (!value) {
    return null;
  }

  const normalized = value.trim().toUpperCase();
  return /^[A-Z]{3}$/.test(normalized) ? normalized : null;
}

function inferCurrencyCode(rawPrice: string | null) {
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
  if (rawPrice.includes("$")) return "USD";

  return null;
}

export function scrapeGenericProduct(html: string): ScrapedProduct {
  const $ = cheerio.load(html);
  const jsonLdOffer = extractJsonLdOffer($);

  const title = firstNonEmpty(
    $('meta[property="og:title"]').attr("content"),
    $("title").text(),
    $("h1").first().text(),
  );
  const description = firstNonEmpty(
    $('meta[name="description"]').attr("content"),
    $('meta[property="og:description"]').attr("content"),
  );
  const imageUrl = firstNonEmpty(
    $('meta[property="og:image"]').attr("content"),
    $('meta[name="twitter:image"]').attr("content"),
  );
  const rawPrice = firstNonEmpty(
    jsonLdOffer.price,
    $('meta[property="product:price:amount"]').attr("content"),
    $('meta[property="og:price:amount"]').attr("content"),
    valueFromSelector($, '[itemprop="price"]'),
    valueFromSelector($, "[data-product-price]"),
    valueFromSelector($, "[data-price]"),
    valueFromSelector($, '[data-testid*="price" i]'),
  );
  const currencyCode = normalizeCurrencyCode(firstNonEmpty(
    jsonLdOffer.currency,
    $('meta[property="product:price:currency"]').attr("content"),
    $('meta[property="og:price:currency"]').attr("content"),
    valueFromSelector($, '[itemprop="priceCurrency"]'),
    inferCurrencyCode(rawPrice),
  ));
  const priceAmount = parsePrice(rawPrice);

  return {
    title,
    description,
    imageUrl,
    priceAmount,
    currencyCode,
  };
}
