import Supabase

struct SupabaseProductSearchService: ProductSearchServing {
    private struct SearchRequest: Encodable {
        let query: String
        let limit: Int
        let marketplaceID: String?

        enum CodingKeys: String, CodingKey {
            case query
            case limit
            case marketplaceID = "marketplace_id"
        }
    }

    let client: SupabaseClient

    func searchProducts(
        query: String,
        homeCurrencyCode: String?
    ) async throws -> ProductSearchResponse {
        try await client.functions.invoke(
            "search-products",
            options: FunctionInvokeOptions(
                body: SearchRequest(
                    query: query,
                    limit: 20,
                    marketplaceID: marketplaceID(
                        for: homeCurrencyCode
                    )
                )
            )
        )
    }

    private func marketplaceID(for currencyCode: String?) -> String? {
        switch currencyCode?.uppercased() {
        case "USD":
            "EBAY_US"
        case "GBP":
            "EBAY_GB"
        case "EUR":
            "EBAY_DE"
        case "AUD":
            "EBAY_AU"
        case "CAD":
            "EBAY_CA"
        case "CHF":
            "EBAY_CH"
        case "HKD":
            "EBAY_HK"
        case "PLN":
            "EBAY_PL"
        case "SGD":
            "EBAY_SG"
        default:
            nil
        }
    }
}
