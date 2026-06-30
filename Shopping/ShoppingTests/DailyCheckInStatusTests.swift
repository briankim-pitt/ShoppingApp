import Foundation
import Testing
@testable import Shopping

struct DailyCheckInStatusTests {
    @Test
    func decodesDailyCheckInStatus() throws {
        let data = Data(
            #"""
            {
              "claimed_today": true,
              "reward_amount": 100,
              "streak_count": 3,
              "claimed_at": "2026-06-30T00:00:00Z",
              "balance": {
                "amount": 1100,
                "currency_code": "WCN"
              }
            }
            """#.utf8
        )

        let status = try JSONDecoder.supabase.decode(
            DailyCheckInStatus.self,
            from: data
        )

        #expect(status.claimedToday)
        #expect(status.rewardAmount == 100)
        #expect(status.streakCount == 3)
        #expect(status.balance.amount == 1100)
    }
}
