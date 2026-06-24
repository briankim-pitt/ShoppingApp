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
});
