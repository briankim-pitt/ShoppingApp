import Foundation
import Testing
@testable import Shopping

struct ProductBrandDecodingTests {
    @Test
    func decodesBrandMatchCount() throws {
        let brands = try decodedBrands(
            """
            [
              { "name": "Wooting", "match_count": 12 }
            ]
            """
        )

        #expect(brands == [
            ProductBrand(name: "Wooting", matchCount: 12),
        ])
    }

    @Test
    func decodesNullBrandMatchCount() throws {
        let brands = try decodedBrands(
            """
            [
              { "name": "Keychron", "match_count": null }
            ]
            """
        )

        #expect(brands == [
            ProductBrand(name: "Keychron", matchCount: nil),
        ])
    }

    private func decodedBrands(_ json: String) throws -> [ProductBrand] {
        try JSONDecoder.supabase.decode(
            [ProductBrand].self,
            from: Data(json.utf8)
        )
    }
}
