protocol ProductSearchServing: Sendable {
    func searchProducts(query: String) async throws -> ProductSearchResponse
}
