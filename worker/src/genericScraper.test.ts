import { describe, expect, it } from "vitest";
import { scrapeGenericProduct } from "./genericScraper.js";

describe("scrapeGenericProduct", () => {
  it("extracts the common product metadata", () => {
    const result = scrapeGenericProduct(`
      <html>
        <head>
          <title>Ignored title</title>
          <meta property="og:title" content="Orbit Lamp" />
          <meta property="og:description" content="A soft desk light." />
          <meta property="og:image" content="https://cdn.example.com/lamp.png" />
          <meta property="product:price:amount" content="49.99" />
          <meta property="product:price:currency" content="usd" />
        </head>
      </html>
    `);

    expect(result).toEqual({
      title: "Orbit Lamp",
      description: "A soft desk light.",
      imageUrl: "https://cdn.example.com/lamp.png",
      priceAmount: 49.99,
      currencyCode: "USD",
    });
  });

  it("extracts price and currency from JSON-LD product offers", () => {
    const result = scrapeGenericProduct(`
      <html>
        <head>
          <meta property="og:title" content="Rapid Keyboard" />
          <script type="application/ld+json">
            {
              "@context": "https://schema.org",
              "@graph": [
                {
                  "@type": "Product",
                  "name": "Rapid Keyboard",
                  "offers": {
                    "@type": "Offer",
                    "price": "179.99",
                    "priceCurrency": "USD"
                  }
                }
              ]
            }
          </script>
        </head>
      </html>
    `);

    expect(result.priceAmount).toBe(179.99);
    expect(result.currencyCode).toBe("USD");
  });

  it("parses localized schema.org prices and currency symbols", () => {
    const result = scrapeGenericProduct(`
      <html>
        <head>
          <meta property="og:title" content="Desk Chair" />
        </head>
        <body>
          <span itemprop="price">€1.299,95</span>
        </body>
      </html>
    `);

    expect(result.priceAmount).toBe(1299.95);
    expect(result.currencyCode).toBe("EUR");
  });

  it("reads price values from non-meta schema.org elements", () => {
    const result = scrapeGenericProduct(`
      <html>
        <head>
          <meta property="og:title" content="Camera" />
        </head>
        <body>
          <data itemprop="price" value="2499.00"></data>
          <span itemprop="priceCurrency">JPY</span>
        </body>
      </html>
    `);

    expect(result.priceAmount).toBe(2499);
    expect(result.currencyCode).toBe("JPY");
  });
});
