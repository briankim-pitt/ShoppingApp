struct ProductSearchResponse: Decodable, Equatable, Sendable {
    let products: [Product]
    let total: Int
    let provider: String
    let marketplaceID: String
    let correctedQuery: String?
    let brands: [ProductBrand]?
    let dominantCategoryID: String?

    enum CodingKeys: String, CodingKey {
        case products
        case total
        case provider
        case marketplaceID = "marketplace_id"
        case correctedQuery = "corrected_query"
        case brands
        case dominantCategoryID = "dominant_category_id"
    }

    var brandRefinements: [ProductBrand] {
        brands ?? []
    }
}
