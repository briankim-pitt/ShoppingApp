struct UnavailableProductSearchService: ProductSearchServing {
    func searchProducts(query: String) async throws -> ProductSearchResponse {
        throw ConfigurationError.missingSupabaseURL
    }
}
