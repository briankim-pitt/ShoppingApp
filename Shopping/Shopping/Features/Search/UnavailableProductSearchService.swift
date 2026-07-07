struct UnavailableProductSearchService: ProductSearchServing {
    func searchProducts(
        query: String,
        brand: String?,
        categoryID: String?
    ) async throws -> ProductSearchResponse {
        throw ConfigurationError.missingSupabaseURL
    }
}
