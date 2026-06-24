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

export function scrapeGenericProduct(html: string): ScrapedProduct {
  const $ = cheerio.load(html);

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
  const currencyCode = firstNonEmpty(
    $('meta[property="product:price:currency"]').attr("content"),
    $('meta[itemprop="priceCurrency"]').attr("content"),
  )?.toUpperCase() ?? null;
  const priceAmount = parsePrice(firstNonEmpty(
    $('meta[property="product:price:amount"]').attr("content"),
    $('meta[itemprop="price"]').attr("content"),
  ));

  return {
    title,
    description,
    imageUrl,
    priceAmount,
    currencyCode,
  };
}
