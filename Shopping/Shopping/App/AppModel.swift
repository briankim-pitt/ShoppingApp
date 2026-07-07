import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let authService: any AuthServing
    private let walletService: any WalletServing
    private let productImportService: any ProductImportServing
    private let productSearchService: any ProductSearchServing
    private let ordersService: any OrdersServing
    private let checkoutService: any CheckoutServing
    private let wishlistService: any WishlistServing

    var phase: AppPhase = .launching
    var wallet: VirtualWallet?
    var dailyCheckInStatus: DailyCheckInStatus?
    var selectedTab: MainTab = .home
    let cart: CartStore

    init(
        authService: any AuthServing,
        walletService: any WalletServing,
        productImportService: any ProductImportServing,
        productSearchService: any ProductSearchServing,
        ordersService: any OrdersServing,
        checkoutService: any CheckoutServing,
        wishlistService: any WishlistServing,
        cart: CartStore = CartStore()
    ) {
        self.authService = authService
        self.walletService = walletService
        self.productImportService = productImportService
        self.productSearchService = productSearchService
        self.ordersService = ordersService
        self.checkoutService = checkoutService
        self.wishlistService = wishlistService
        self.cart = cart
    }

    static func live() -> AppModel {
        do {
            let dependencies = try LiveDependencies()
            return AppModel(
                authService: dependencies.authService,
                walletService: dependencies.walletService,
                productImportService: dependencies.productImportService,
                productSearchService: dependencies.productSearchService,
                ordersService: dependencies.ordersService,
                checkoutService: dependencies.checkoutService,
                wishlistService: dependencies.wishlistService
            )
        } catch {
            let model = AppModel(
                authService: UnavailableAuthService(),
                walletService: UnavailableWalletService(),
                productImportService: UnavailableProductImportService(),
                productSearchService: UnavailableProductSearchService(),
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
        selectedTab = .home
        phase = .signedOut
    }

    func importProduct(from url: URL) async throws -> ProductImportResult {
        try await productImportService.importProduct(from: url)
    }

    func searchProducts(
        query: String,
        brand: String? = nil,
        categoryID: String? = nil
    ) async throws -> ProductSearchResponse {
        try await productSearchService.searchProducts(
            query: query,
            brand: brand,
            categoryID: categoryID
        )
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
