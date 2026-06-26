struct UnavailableWalletService: WalletServing {
    func getWallet() async throws -> VirtualWallet {
        throw ConfigurationError.missingSupabaseURL
    }
}
