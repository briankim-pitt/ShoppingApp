import Foundation

struct Product: Decodable, Equatable, Hashable, Identifiable, Sendable {
    let id: UUID
    let canonicalURL: URL
    let sourceDomain: String
    let title: String
    let description: String?
    let brand: String?
    let imageURL: URL?
    let currencyCode: String?
    let priceAmount: Decimal?
    let wanderCoinPriceAmount: Decimal?
    let createdAt: Date
    let updatedAt: Date
    let lastImportedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case canonicalURL = "canonical_url"
        case sourceDomain = "source_domain"
        case title
        case description
        case brand
        case imageURL = "image_url"
        case currencyCode = "currency_code"
        case priceAmount = "price_amount"
        case wanderCoinPriceAmount = "wandercoin_price_amount"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastImportedAt = "last_imported_at"
    }

    var priceText: String {
        guard let priceAmount, let currencyCode else {
            return "Price unavailable"
        }

        return priceAmount.formatted(.currency(code: currencyCode).presentation(.narrow))
    }

    var wanderCoinPriceText: String {
        wanderCoinPriceAmount?
            .roundedUpToWholeCoin
            .wanderCoinText ?? "Set coin price in cart"
    }
}
