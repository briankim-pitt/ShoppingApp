import Foundation

struct CartCheckoutResult: Decodable, Equatable, Sendable {
    let order: PlacedVirtualOrder
    let items: [VirtualOrderItem]
    let balance: Money
    let idempotentReplay: Bool

    enum CodingKeys: String, CodingKey {
        case order
        case items
        case balance
        case idempotentReplay = "idempotent_replay"
    }
}

struct PlacedVirtualOrder: Decodable, Equatable, Identifiable, Sendable {
    let id: UUID
    let status: VirtualOrderStatus
    let totalAmount: Decimal
    let currencyCode: String
    let estimatedDeliveryAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case totalAmount = "total_amount"
        case currencyCode = "currency_code"
        case estimatedDeliveryAt = "estimated_delivery_at"
    }
}
