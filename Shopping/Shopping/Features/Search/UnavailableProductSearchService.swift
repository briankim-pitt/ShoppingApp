struct UnavailableProductSearchService: ProductSearchServing {
    func searchProducts(
        query: String,
        homeCurrencyCode: String?
    ) async throws -> ProductSearchResponse {
        throw ConfigurationError.missingSupabaseURL
    }
}
