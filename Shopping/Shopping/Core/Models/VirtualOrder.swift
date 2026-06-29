import Foundation

struct VirtualOrder: Decodable, Equatable, Identifiable, Sendable {
    let id: UUID
    let status: VirtualOrderStatus
    let totalAmount: Decimal
    let currencyCode: String?
    let placedAt: Date?
    let processingAt: Date?
    let shippedAt: Date?
    let outForDeliveryAt: Date?
    let deliveredAt: Date?
    let cancelledAt: Date?
    let estimatedDeliveryAt: Date?
    let nextStatusAt: Date?
    let createdAt: Date
    let items: [VirtualOrderItem]
    let events: [VirtualOrderStatusEvent]

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case totalAmount = "total_amount"
        case currencyCode = "currency_code"
        case placedAt = "placed_at"
        case processingAt = "processing_at"
        case shippedAt = "shipped_at"
        case outForDeliveryAt = "out_for_delivery_at"
        case deliveredAt = "delivered_at"
        case cancelledAt = "cancelled_at"
        case estimatedDeliveryAt = "estimated_delivery_at"
        case nextStatusAt = "next_status_at"
        case createdAt = "created_at"
        case items = "virtual_order_items"
        case events = "virtual_order_status_events"
    }

    var totalText: String {
        totalAmount.wanderCoinText
    }

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var primaryItemTitle: String {
        items.first?.title ?? "Virtual Order"
    }

    var orderedAt: Date {
        placedAt ?? createdAt
    }

    var trackingStatuses: [VirtualOrderStatus] {
        guard status == .cancelled else {
            return VirtualOrderStatus.shippingStages
        }

        let completedStatuses = VirtualOrderStatus.shippingStages.filter {
            event(for: $0) != nil
        }
        return completedStatuses + [.cancelled]
    }

    func event(for status: VirtualOrderStatus) -> VirtualOrderStatusEvent? {
        events.first { $0.status == status }
    }
}
