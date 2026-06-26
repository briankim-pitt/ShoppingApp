protocol WalletServing: Sendable {
    func getWallet() async throws -> VirtualWallet
}
