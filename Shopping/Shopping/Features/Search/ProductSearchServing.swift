protocol ProductSearchServing: Sendable {
    func searchProducts(
        query: String,
        brand: String?,
        categoryID: String?
    ) async throws -> ProductSearchResponse
}

extension ProductSearchServing {
    func searchProducts(query: String) async throws -> ProductSearchResponse {
        try await searchProducts(query: query, brand: nil, categoryID: nil)
    }
}
