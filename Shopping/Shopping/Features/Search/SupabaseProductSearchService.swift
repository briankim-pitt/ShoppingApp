import Supabase

struct SupabaseProductSearchService: ProductSearchServing {
    private struct SearchRequest: Encodable {
        let query: String
        let limit: Int
        let brand: String?
        let categoryID: String?

        enum CodingKeys: String, CodingKey {
            case query
            case limit
            case brand
            case categoryID = "category_id"
        }
    }

    let client: SupabaseClient

    func searchProducts(
        query: String,
        brand: String?,
        categoryID: String?
    ) async throws -> ProductSearchResponse {
        try await client.functions.invoke(
            "search-products",
            options: FunctionInvokeOptions(
                body: SearchRequest(
                    query: query,
                    limit: 20,
                    brand: brand,
                    categoryID: categoryID
                )
            )
        )
    }
}
