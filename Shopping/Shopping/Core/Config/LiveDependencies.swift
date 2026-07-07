import Supabase

@MainActor
struct LiveDependencies {
    let client: SupabaseClient
    let authService: SupabaseAuthService
    let walletService: SupabaseWalletService
    let productImportService: SupabaseProductImportService
    let catalogService: SupabaseCatalogService
    let ordersService: SupabaseOrdersService
    let checkoutService: SupabaseCheckoutService
    let wishlistService: SupabaseWishlistService

    init() throws {
        try self.init(configuration: AppConfiguration())
    }

    init(configuration: AppConfiguration) {
        let client = SupabaseClient(
            supabaseURL: configuration.supabaseURL,
            supabaseKey: configuration.supabasePublishableKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                ),
                functions: .init(decoder: .supabase)
            )
        )

        self.client = client
        authService = SupabaseAuthService(client: client)
        walletService = SupabaseWalletService(client: client)
        productImportService = SupabaseProductImportService(client: client)
        catalogService = SupabaseCatalogService(client: client)
        ordersService = SupabaseOrdersService(client: client)
        checkoutService = SupabaseCheckoutService(client: client)
        wishlistService = SupabaseWishlistService(client: client)
    }
}
