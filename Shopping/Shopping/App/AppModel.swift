import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let authService: any AuthServing
    private let walletService: any WalletServing
    private let productImportService: any ProductImportServing
    private let catalogService: any CatalogServing
    private let ordersService: any OrdersServing
    private let checkoutService: any CheckoutServing
    private let wishlistService: any WishlistServing

    var phase: AppPhase = .launching
    var userEmail: String?
    var wallet: VirtualWallet?
    var dailyCheckInStatus: DailyCheckInStatus?
    var selectedTab: MainTab = .home
    var pendingProductImport: PendingProductImport?
    var deletedImportedProductID: UUID?
    let cart: CartStore
    let recentlyViewed: RecentlyViewedStore

    init(
        authService: any AuthServing,
        walletService: any WalletServing,
        productImportService: any ProductImportServing,
        catalogService: any CatalogServing,
        ordersService: any OrdersServing,
        checkoutService: any CheckoutServing,
        wishlistService: any WishlistServing,
        cart: CartStore = CartStore(),
        recentlyViewed: RecentlyViewedStore = RecentlyViewedStore()
    ) {
        self.authService = authService
        self.walletService = walletService
        self.productImportService = productImportService
        self.catalogService = catalogService
        self.ordersService = ordersService
        self.checkoutService = checkoutService
        self.wishlistService = wishlistService
        self.cart = cart
        self.recentlyViewed = recentlyViewed
    }

    static func live() -> AppModel {
        do {
            let dependencies = try LiveDependencies()
            return AppModel(
                authService: dependencies.authService,
                walletService: dependencies.walletService,
                productImportService: dependencies.productImportService,
                catalogService: dependencies.catalogService,
                ordersService: dependencies.ordersService,
                checkoutService: dependencies.checkoutService,
                wishlistService: dependencies.wishlistService
            )
        } catch {
            let model = AppModel(
                authService: UnavailableAuthService(),
                walletService: UnavailableWalletService(),
                productImportService: UnavailableProductImportService(),
                catalogService: UnavailableCatalogService(),
                ordersService: UnavailableOrdersService(),
                checkoutService: UnavailableCheckoutService(),
                wishlistService: UnavailableWishlistService()
            )
            model.phase = .configurationError(error.localizedDescription)
            return model
        }
    }

    func start() async {
        guard case .launching = phase else { return }

        do {
            guard try await authService.hasSession() else {
                phase = .signedOut
                return
            }
            await refreshWallet()
        } catch {
            phase = .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
        await refreshWallet()
    }

    func signUp(email: String, password: String) async throws {
        try await authService.signUp(email: email, password: password)
        await refreshWallet()
    }

    func signOut() async {
        try? await authService.signOut()
        cart.clear()
        wallet = nil
        dailyCheckInStatus = nil
        userEmail = nil
        selectedTab = .home
        phase = .signedOut
    }

    func loadUserEmail() async {
        userEmail = await authService.currentEmail()
    }

    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata? = nil
    ) async throws -> ProductImportResult {
        try await productImportService.importProduct(
            from: url,
            extracted: extracted
        )
    }

    func deleteImport(forProductID productID: UUID) async throws {
        try await productImportService.deleteImport(forProductID: productID)
        cart.remove(productID: productID)
        deletedImportedProductID = productID
    }

    func handleIncomingURL(_ url: URL) {
        guard let pending = PendingProductImport(deepLink: url) else {
            return
        }

        selectedTab = .search
        pendingProductImport = pending
    }

    func consumePendingProductImport() -> PendingProductImport? {
        defer { pendingProductImport = nil }
        return pendingProductImport
    }

    func browseProducts() async throws -> [Product] {
        try await catalogService.browseProducts()
    }

    func searchProducts(query: String) async throws -> [Product] {
        try await catalogService.searchProducts(query: query)
    }

    func products(forBrand brand: String) async throws -> [Product] {
        try await catalogService.products(forBrand: brand)
    }

    func listBrands() async throws -> [ProductBrand] {
        try await catalogService.listBrands()
    }

    func heroImage(forProductID productID: UUID) async throws -> URL? {
        try await catalogService.heroImage(forProductID: productID)
    }

    func listOrders() async throws -> [VirtualOrder] {
        try await ordersService.listOrders()
    }

    func isInWishlist(productID: UUID) async throws -> Bool {
        try await wishlistService.contains(productID: productID)
    }

    func addToWishlist(productID: UUID) async throws {
        try await wishlistService.add(productID: productID)
    }

    func checkoutCart(idempotencyKey: UUID) async throws -> CartCheckoutResult {
        guard !cart.items.isEmpty else {
            throw APIError.message("Your cart is empty.")
        }

        let result = try await checkoutService.checkout(
            items: cart.items,
            idempotencyKey: idempotencyKey
        )
        wallet = VirtualWallet(
            balance: result.balance,
            homeCurrencySelected: true,
            homeCurrencySelectedAt: wallet?.homeCurrencySelectedAt
        )
        return result
    }

    func claimDailyCheckIn() async throws {
        let status = try await walletService.claimDailyCheckIn()
        dailyCheckInStatus = status
        wallet = VirtualWallet(
            balance: status.balance,
            homeCurrencySelected: true,
            homeCurrencySelectedAt: wallet?.homeCurrencySelectedAt
        )
    }

    func addPreviewCoin() {
        guard let wallet else { return }

        self.wallet = VirtualWallet(
            balance: Money(
                amount: wallet.balance.amount + 1,
                currencyCode: wallet.balance.currencyCode
            ),
            homeCurrencySelected: wallet.homeCurrencySelected,
            homeCurrencySelectedAt: wallet.homeCurrencySelectedAt
        )
    }

    func refreshWallet() async {
        do {
            let wallet = try await walletService.getWallet()
            self.wallet = wallet
            dailyCheckInStatus = try? await walletService
                .getDailyCheckInStatus()
            phase = .ready
        } catch {
            phase = .signedOut
        }
    }
}
