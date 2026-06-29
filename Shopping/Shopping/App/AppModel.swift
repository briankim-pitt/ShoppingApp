import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let authService: any AuthServing
    private let walletService: any WalletServing
    private let onboardingService: any OnboardingServing
    private let productImportService: any ProductImportServing
    private let productSearchService: any ProductSearchServing
    private let ordersService: any OrdersServing
    private let checkoutService: any CheckoutServing

    var phase: AppPhase = .launching
    var wallet: VirtualWallet?
    var selectedTab: MainTab = .home
    let cart: CartStore

    init(
        authService: any AuthServing,
        walletService: any WalletServing,
        onboardingService: any OnboardingServing,
        productImportService: any ProductImportServing,
        productSearchService: any ProductSearchServing,
        ordersService: any OrdersServing,
        checkoutService: any CheckoutServing,
        cart: CartStore = CartStore()
    ) {
        self.authService = authService
        self.walletService = walletService
        self.onboardingService = onboardingService
        self.productImportService = productImportService
        self.productSearchService = productSearchService
        self.ordersService = ordersService
        self.checkoutService = checkoutService
        self.cart = cart
    }

    static func live() -> AppModel {
        do {
            let dependencies = try LiveDependencies()
            return AppModel(
                authService: dependencies.authService,
                walletService: dependencies.walletService,
                onboardingService: dependencies.onboardingService,
                productImportService: dependencies.productImportService,
                productSearchService: dependencies.productSearchService,
                ordersService: dependencies.ordersService,
                checkoutService: dependencies.checkoutService
            )
        } catch {
            let model = AppModel(
                authService: UnavailableAuthService(),
                walletService: UnavailableWalletService(),
                onboardingService: UnavailableOnboardingService(),
                productImportService: UnavailableProductImportService(),
                productSearchService: UnavailableProductSearchService(),
                ordersService: UnavailableOrdersService(),
                checkoutService: UnavailableCheckoutService()
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
        selectedTab = .home
        phase = .signedOut
    }

    func listCurrencies() async throws -> [SupportedCurrency] {
        try await onboardingService.listCurrencies()
    }

    func selectHomeCurrency(_ currencyCode: String) async throws {
        wallet = try await onboardingService.setHomeCurrency(currencyCode)
        phase = .ready
    }

    func importProduct(from url: URL) async throws -> ProductImportResult {
        try await productImportService.importProduct(from: url)
    }

    func searchProducts(query: String) async throws -> ProductSearchResponse {
        try await productSearchService.searchProducts(
            query: query,
            homeCurrencyCode: wallet?.balance.currencyCode
        )
    }

    func listOrders() async throws -> [VirtualOrder] {
        try await ordersService.listOrders()
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

    func refreshWallet() async {
        do {
            let wallet = try await walletService.getWallet()
            self.wallet = wallet
            phase = wallet.homeCurrencySelected ? .ready : .needsCurrency
        } catch {
            phase = .signedOut
        }
    }
}
