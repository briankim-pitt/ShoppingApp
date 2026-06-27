enum VirtualOrderStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case ordered
    case processing
    case shipped
    case outForDelivery = "out_for_delivery"
    case delivered
    case cancelled

    var id: Self { self }

    static let shippingStages: [VirtualOrderStatus] = [
        .ordered,
        .processing,
        .shipped,
        .outForDelivery,
        .delivered,
    ]

    var title: String {
        switch self {
        case .ordered:
            "Ordered"
        case .processing:
            "Processing"
        case .shipped:
            "Shipped"
        case .outForDelivery:
            "Out for Delivery"
        case .delivered:
            "Delivered"
        case .cancelled:
            "Cancelled"
        }
    }

    var systemImage: String {
        switch self {
        case .ordered:
            "checkmark.circle"
        case .processing:
            "shippingbox"
        case .shipped:
            "truck.box"
        case .outForDelivery:
            "truck.box.fill"
        case .delivered:
            "house.and.flag"
        case .cancelled:
            "xmark.circle"
        }
    }
}
