struct UnavailableWalletService: WalletServing {
    func getWallet() async throws -> VirtualWallet {
        throw ConfigurationError.missingSupabaseURL
    }

    func getDailyCheckInStatus() async throws -> DailyCheckInStatus {
        throw ConfigurationError.missingSupabaseURL
    }

    func claimDailyCheckIn() async throws -> DailyCheckInStatus {
        throw ConfigurationError.missingSupabaseURL
    }
}
