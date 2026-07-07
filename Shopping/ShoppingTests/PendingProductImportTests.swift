import Foundation
import Testing
@testable import Shopping

struct PendingProductImportTests {
    private func pendingImport(
        fromDeepLink string: String
    ) throws -> PendingProductImport? {
        let url = try #require(URL(string: string))
        return PendingProductImport(deepLink: url)
    }

    @Test
    func parsesURLOnlyDeepLink() throws {
        let pending = try #require(try pendingImport(
            fromDeepLink: "shopping://import-product?url=https%3A%2F%2Fexample.com%2Fitem"
        ))

        #expect(pending.url.absoluteString == "https://example.com/item")
        #expect(pending.extracted == nil)
    }

    @Test
    func parsesExtractedMetadata() throws {
        let pending = try #require(try pendingImport(
            fromDeepLink: "shopping://import-product?url=https%3A%2F%2Fexample.com%2Fitem&title=Air%20Force%201&price=101.99&currency=usd&brand=Nike&image=https%3A%2F%2Fexample.com%2Fa.jpg"
        ))

        let extracted = try #require(pending.extracted)
        #expect(extracted.title == "Air Force 1")
        #expect(extracted.priceAmount == Decimal(string: "101.99"))
        #expect(extracted.currencyCode == "USD")
        #expect(extracted.brand == "Nike")
        #expect(extracted.imageURL?.absoluteString == "https://example.com/a.jpg")
        #expect(extracted.description == nil)
    }

    @Test
    func ignoresMetadataWithoutTitle() throws {
        let pending = try #require(try pendingImport(
            fromDeepLink: "shopping://import-product?url=https%3A%2F%2Fexample.com&price=10"
        ))

        #expect(pending.extracted == nil)
    }

    @Test
    func rejectsWrongSchemeOrHost() throws {
        #expect(try pendingImport(
            fromDeepLink: "https://import-product?url=https%3A%2F%2Fexample.com"
        ) == nil)
        #expect(try pendingImport(
            fromDeepLink: "shopping://other?url=https%3A%2F%2Fexample.com"
        ) == nil)
        #expect(try pendingImport(
            fromDeepLink: "shopping://import-product"
        ) == nil)
    }

    @Test
    func invalidPriceBecomesNil() throws {
        let pending = try #require(try pendingImport(
            fromDeepLink: "shopping://import-product?url=https%3A%2F%2Fexample.com&title=Item&price=free"
        ))

        #expect(pending.extracted?.priceAmount == nil)
    }
}
