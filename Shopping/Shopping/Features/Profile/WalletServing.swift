protocol WalletServing: Sendable {
    func getWallet() async throws -> VirtualWallet
    func getDailyCheckInStatus() async throws -> DailyCheckInStatus
    func claimDailyCheckIn() async throws -> DailyCheckInStatus
}
