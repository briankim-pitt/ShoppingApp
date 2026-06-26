struct UnavailableOnboardingService: OnboardingServing {
    func listCurrencies() async throws -> [SupportedCurrency] {
        throw ConfigurationError.missingSupabaseURL
    }

    func setHomeCurrency(_ currencyCode: String) async throws -> VirtualWallet {
        throw ConfigurationError.missingSupabaseURL
    }
}
