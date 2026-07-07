const api = typeof browser !== "undefined" ? browser : chrome;

// Runs inside the page, so it sees the fully rendered DOM.
function extractProductData() {
  const text = (value) =>
    typeof value === "string" || typeof value === "number"
      ? String(value).trim()
      : "";
  const meta = (selector) =>
    document.querySelector(selector)?.getAttribute("content")?.trim() ?? "";

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

  const rawPrice =
    text(offer.price) ||
    text(offer.lowPrice) ||
    text(priceSpec.price) ||
    meta('meta[property="product:price:amount"]') ||
    document.querySelector('[itemprop="price"]')?.getAttribute("content") ||
    "";
  const parsedPrice = Number.parseFloat(rawPrice.replace(/[^0-9.]/g, ""));

  return {
    title: (
      text(product?.name) ||
      meta('meta[property="og:title"]') ||
      document.title.trim()
    ).slice(0, 200),
    description: (
      text(product?.description) ||
      meta('meta[name="description"]') ||
      meta('meta[property="og:description"]')
    ).slice(0, 300),
    image:
      text(typeof image === "object" ? image?.url : image) ||
      meta('meta[property="og:image"]'),
    brand: text(
      typeof product?.brand === "object" ? product?.brand?.name : product?.brand,
    ).slice(0, 120),
    price: Number.isFinite(parsedPrice) && parsedPrice >= 0
      ? String(parsedPrice)
      : "",
    currency: (
      text(offer.priceCurrency) ||
      text(priceSpec.priceCurrency) ||
      meta('meta[property="product:price:currency"]')
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
