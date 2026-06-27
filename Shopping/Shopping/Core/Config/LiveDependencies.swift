import Supabase

@MainActor
struct LiveDependencies {
    let client: SupabaseClient
    let authService: SupabaseAuthService
    let walletService: SupabaseWalletService
    let onboardingService: SupabaseOnboardingService
    let productImportService: SupabaseProductImportService
    let ordersService: SupabaseOrdersService

    init() throws {
        try self.init(configuration: AppConfiguration())
    }

    init(configuration: AppConfiguration) {
        let client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.supabasePublishableKey
        )

        self.client = client
        authService = SupabaseAuthService(client: client)
        walletService = SupabaseWalletService(client: client)
        onboardingService = SupabaseOnboardingService(client: client)
        productImportService = SupabaseProductImportService(client: client)
        ordersService = SupabaseOrdersService(client: client)
    }
}
