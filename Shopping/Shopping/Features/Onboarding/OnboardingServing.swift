protocol OnboardingServing: Sendable {
    func listCurrencies() async throws -> [SupportedCurrency]
    func setHomeCurrency(_ currencyCode: String) async throws -> VirtualWallet
}
