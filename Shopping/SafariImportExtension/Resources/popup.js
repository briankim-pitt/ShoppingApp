const api = typeof browser !== "undefined" ? browser : chrome;

// Runs inside the page, so it sees the fully rendered DOM.
function extractProductData() {
  const text = (value) =>
    typeof value === "string" || typeof value === "number"
      ? String(value).trim()
      : "";
  const meta = (selector) =>
    document.querySelector(selector)?.getAttribute("content")?.trim() ?? "";
  const attr = (selector, name) =>
    document.querySelector(selector)?.getAttribute(name)?.trim() ?? "";
  const firstText = (...selectors) => {
    for (const selector of selectors) {
      const value = document.querySelector(selector)?.textContent?.trim();
      if (value) return value;
    }
    return "";
  };
  const firstAttr = (selectors, names) => {
    for (const selector of selectors) {
      const element = document.querySelector(selector);
      if (!element) continue;

      for (const name of names) {
        const value = name === "currentSrc"
          ? element.currentSrc
          : element.getAttribute(name);
        if (value?.trim()) return value.trim();
      }
    }
    return "";
  };
  const firstSrcSetURL = (srcset) =>
    text(srcset).split(",").map((entry) => entry.trim().split(/\s+/)[0])
      .find(Boolean) ?? "";
  const escaped = (value) => {
    if (!value) return "";
    return value.replace(/["\\]/g, "\\$&");
  };
  const normalizeURL = (value) => {
    try {
      return value ? new URL(value, document.location.href).href : "";
    } catch {
      return "";
    }
  };
  const parsePrice = (value) => {
    const match = text(value).match(/(?:USD|CAD|AUD)?\s*[$€£¥]\s*\d[\d,.]*/i)
      ?? text(value).match(/\b\d[\d,.]*\s*(?:USD|CAD|AUD|EUR|GBP|JPY)\b/i);
    if (!match) return "";

    const parsed = Number.parseFloat(match[0].replace(/[^0-9.]/g, ""));
    return Number.isFinite(parsed) && parsed >= 0 ? String(parsed) : "";
  };
  const currencyFrom = (value) => {
    const raw = text(value);
    const explicit = raw.match(/\b(USD|CAD|AUD|EUR|GBP|JPY)\b/i)?.[1];
    if (explicit) return explicit.toUpperCase();
    if (raw.includes("€")) return "EUR";
    if (raw.includes("£")) return "GBP";
    if (raw.includes("¥")) return "JPY";
    if (raw.includes("$")) return "USD";
    return "";
  };

  let product = null;
  for (const script of document.querySelectorAll(
    'script[type="application/ld+json"]',
  )) {
    try {
      const stack = [JSON.parse(script.textContent)];
      while (stack.length && !product) {
        const node = stack.pop();
        if (Array.isArray(node)) {
          stack.push(...node);
          continue;
        }
        if (!node || typeof node !== "object") continue;
        const types = [].concat(node["@type"] ?? []);
        if (types.some((t) => String(t).toLowerCase() === "product")) {
          product = node;
        } else if (node["@graph"]) {
          stack.push(node["@graph"]);
        }
      }
    } catch {
      // Ignore invalid JSON-LD blocks.
    }
    if (product) break;
  }

  const offer = [].concat(product?.offers ?? [])[0] ?? {};
  const priceSpec = offer.priceSpecification ?? {};
  const image = [].concat(product?.image ?? [])[0];
  const skuId = new URL(document.location.href).searchParams.get("skuId") ?? "";
  const skuSelectors = skuId
    ? [
      `img[src*="${escaped(skuId)}"]`,
      `img[currentSrc*="${escaped(skuId)}"]`,
      `img[srcset*="${escaped(skuId)}"]`,
      `source[srcset*="${escaped(skuId)}"]`,
    ]
    : [];
  const productImageSelectors = [
    ...skuSelectors,
    '[data-at="product_image"] img',
    '[data-comp*="ProductImage"] img',
    '[data-comp*="ProductImages"] img',
    '[data-comp*="ProductMedia"] img',
    '[aria-label*="product image" i] img',
    'img[src*="/productimages/sku/"]',
    'img[srcset*="/productimages/sku/"]',
    'source[srcset*="/productimages/sku/"]',
    'img[src*="/productimages/"]',
    'img[srcset*="/productimages/"]',
    'source[srcset*="/productimages/"]',
    'main picture img',
  ];
  const renderedProductImage =
    firstAttr(productImageSelectors, ["currentSrc", "src", "data-src"]) ||
    firstSrcSetURL(firstAttr(productImageSelectors, ["srcset"]));
  const rawImage =
    renderedProductImage ||
    text(typeof image === "object" ? image?.url : image) ||
    meta('meta[property="og:image"]') ||
    meta('meta[name="twitter:image"]') ||
    attr('link[rel="image_src"]', "href");
  const rawPriceText =
    text(offer.price) ||
    text(offer.lowPrice) ||
    text(priceSpec.price) ||
    meta('meta[property="product:price:amount"]') ||
    attr('[itemprop="price"]', "content") ||
    firstText(
      '[data-at="price_sale"]',
      '[data-at="price_regular"]',
      '[data-at="product_price"]',
      '[data-comp*="Price"]',
      '[class*="price" i]',
    );

  const rawPrice =
    parsePrice(rawPriceText) ||
    parsePrice(document.querySelector("main")?.textContent ?? "");

  return {
    title: (
      text(product?.name) ||
      firstText('[data-at="product_name"]') ||
      meta('meta[property="og:title"]') ||
      document.title.trim()
    ).slice(0, 200),
    description: (
      text(product?.description) ||
      meta('meta[name="description"]') ||
      meta('meta[property="og:description"]')
    ).slice(0, 300),
    image: normalizeURL(rawImage),
    brand: text(
      typeof product?.brand === "object" ? product?.brand?.name : product?.brand,
    ) || firstText('[data-at="brand_name"]').slice(0, 120),
    price: rawPrice,
    currency: (
      text(offer.priceCurrency) ||
      text(priceSpec.priceCurrency) ||
      meta('meta[property="product:price:currency"]') ||
      currencyFrom(rawPriceText)
    ).slice(0, 3),
  };
}

function importLink(productURL, data) {
  const params = new URLSearchParams({ url: productURL });
  for (const key of ["title", "description", "image", "brand", "price", "currency"]) {
    if (data?.[key]) {
      params.set(key, data[key]);
    }
  }
  // URLSearchParams encodes spaces as "+" (form encoding), but the app parses
  // the deep link with RFC 3986 rules where "+" is literal. Emit "%20" so
  // spaces survive. Literal "+" characters are already encoded as "%2B".
  const query = params.toString().replace(/\+/g, "%20");
  return `shopping://import-product?${query}`;
}

async function setUp() {
  const status = document.getElementById("status");
  const host = document.getElementById("page-host");
  const link = document.getElementById("import-link");

  let tab;
  try {
    [tab] = await api.tabs.query({ active: true, currentWindow: true });
  } catch {
    status.textContent = "Couldn't read the current page.";
    return;
  }

  const url = tab?.url ?? "";
  if (!/^https?:/.test(url)) {
    status.textContent = "Open a product page to import it.";
    return;
  }

  host.textContent = new URL(url).hostname;
  host.hidden = false;

  let data = null;
  try {
    [{ result: data }] = await api.scripting.executeScript({
      target: { tabId: tab.id },
      func: extractProductData,
    });
  } catch {
    // Fall back to a URL-only import; the server fetches the page itself.
  }

  if (data?.title) {
    status.textContent = data.price
      ? `${data.title} — ${data.currency || ""} ${data.price}`.trim()
      : data.title;
  } else {
    status.textContent = "Send this page to WanderCart:";
  }

  link.href = importLink(url, data);
  link.hidden = false;
}

setUp();
