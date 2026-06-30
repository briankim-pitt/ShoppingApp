import Foundation

struct DailyCheckInStatus: Codable, Equatable, Sendable {
    let claimedToday: Bool
    let rewardAmount: Decimal
    let streakCount: Int
    let claimedAt: Date?
    let balance: Money

    enum CodingKeys: String, CodingKey {
        case claimedToday = "claimed_today"
        case rewardAmount = "reward_amount"
        case streakCount = "streak_count"
        case claimedAt = "claimed_at"
        case balance
    }
}
