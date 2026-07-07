import Foundation

struct ExtractedProductMetadata: Encodable, Equatable, Sendable {
    let title: String
    let description: String?
    let imageURL: URL?
    let priceAmount: Decimal?
    let currencyCode: String?
    let brand: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case imageURL = "image_url"
        case priceAmount = "price_amount"
        case currencyCode = "currency_code"
        case brand
    }
}
