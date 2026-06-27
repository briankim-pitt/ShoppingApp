import Foundation

struct VirtualOrderStatusEvent: Decodable, Equatable, Identifiable, Sendable {
    let id: Int64
    let status: VirtualOrderStatus
    let occurredAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case occurredAt = "occurred_at"
    }
}
