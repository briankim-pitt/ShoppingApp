import Foundation
import Testing
@testable import Shopping

struct ProductSearchBrandTests {
    @Test
    func responseDecodesBrandRefinements() throws {
        let response = try decodedResponse(
            """
            {
              "products": [],
              "total": 0,
              "provider": "ebay",
              "marketplace_id": "EBAY_US",
              "corrected_query": null,
              "brands": [
                { "name": "Wooting", "match_count": 12 },
                { "name": "Keychron", "match_count": null }
              ],
              "dominant_category_id": "33963"
            }
            """
        )

        #expect(response.brandRefinements == [
            ProductBrand(name: "Wooting", matchCount: 12),
            ProductBrand(name: "Keychron", matchCount: nil),
        ])
        #expect(response.dominantCategoryID == "33963")
    }

    @Test
    func responseWithoutBrandFieldsStillDecodes() throws {
        let response = try decodedResponse(
            """
            {
              "products": [],
              "total": 0,
              "provider": "ebay",
              "marketplace_id": "EBAY_US",
              "corrected_query": null
            }
            """
        )

        #expect(response.brandRefinements.isEmpty)
        #expect(response.dominantCategoryID == nil)
    }

    @Test
    func productDecodesOptionalBrand() throws {
        let json = """
            {
              "id": "231525F8-2C65-4B6F-BAF3-DDAA68958549",
              "canonical_url": "https://www.ebay.com/itm/100000000001",
              "source_domain": "www.ebay.com",
              "title": "Wooting 60HE+",
              "description": null,
              "brand": "Wooting",
              "image_url": null,
              "currency_code": "USD",
              "price_amount": 174.99,
              "wandercoin_price_amount": 175,
              "created_at": "2026-07-07T00:00:00Z",
              "updated_at": "2026-07-07T00:00:00Z",
              "last_imported_at": "2026-07-07T00:00:00Z"
            }
            """

        let product = try JSONDecoder.supabase.decode(
            Product.self,
            from: Data(json.utf8)
        )

        #expect(product.brand == "Wooting")
    }

    private func decodedResponse(
        _ json: String
    ) throws -> ProductSearchResponse {
        try JSONDecoder.supabase.decode(
            ProductSearchResponse.self,
            from: Data(json.utf8)
        )
    }
}
