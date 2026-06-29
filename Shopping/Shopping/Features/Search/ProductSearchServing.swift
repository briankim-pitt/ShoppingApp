protocol ProductSearchServing: Sendable {
    func searchProducts(
        query: String,
        homeCurrencyCode: String?
    ) async throws -> ProductSearchResponse
}
