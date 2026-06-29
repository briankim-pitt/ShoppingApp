struct ProductSearchResponse: Decodable, Equatable, Sendable {
    let products: [Product]
    let total: Int
    let provider: String
    let marketplaceID: String
    let correctedQuery: String?

    enum CodingKeys: String, CodingKey {
        case products
        case total
        case provider
        case marketplaceID = "marketplace_id"
        case correctedQuery = "corrected_query"
    }
}
