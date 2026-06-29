import Supabase

struct SupabaseProductSearchService: ProductSearchServing {
    private struct SearchRequest: Encodable {
        let query: String
        let limit: Int

        enum CodingKeys: String, CodingKey {
            case query
            case limit
        }
    }

    let client: SupabaseClient

    func searchProducts(query: String) async throws -> ProductSearchResponse {
        try await client.functions.invoke(
            "search-products",
            options: FunctionInvokeOptions(
                body: SearchRequest(
                    query: query,
                    limit: 20
                )
            )
        )
    }
}
