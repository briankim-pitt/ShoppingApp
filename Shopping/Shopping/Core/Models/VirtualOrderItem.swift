import Foundation

struct VirtualOrderItem: Decodable, Equatable, Identifiable, Sendable {
    let id: UUID
    let productID: UUID?
    let title: String
    let imageURL: URL?
    let currencyCode: String?
    let unitPriceAmount: Decimal
    let quantity: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case productID = "product_id"
        case title = "title_snapshot"
        case imageURL = "image_url_snapshot"
        case currencyCode = "currency_code"
        case unitPriceAmount = "unit_price_amount"
        case quantity
        case createdAt = "created_at"
    }

    var totalPriceText: String {
        let total = unitPriceAmount * Decimal(quantity)
        return total.wanderCoinNumber
    }
}
