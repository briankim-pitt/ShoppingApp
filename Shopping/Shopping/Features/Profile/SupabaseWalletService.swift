import Supabase

struct SupabaseWalletService: WalletServing {
    let client: SupabaseClient

    func getWallet() async throws -> VirtualWallet {
        try await client
            .rpc("get_my_wallet")
            .execute()
            .value
    }

    func getDailyCheckInStatus() async throws -> DailyCheckInStatus {
        try await client
            .rpc("get_daily_check_in_status")
            .execute()
            .value
    }

    func claimDailyCheckIn() async throws -> DailyCheckInStatus {
        try await client
            .rpc("claim_daily_check_in")
            .execute()
            .value
    }
}
