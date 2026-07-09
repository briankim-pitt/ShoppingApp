import Foundation
import Testing
@testable import Shopping

@MainActor
struct CartViewModelCheckoutAuthTests {
    @Test
    func confirmedAuthenticationPlacesOrder() async {
        let checkout = SpyCheckoutService()
        let (viewModel, appModel) = makeSubjects(
            authResult: .confirmed,
            checkout: checkout
        )

        await viewModel.checkout(using: appModel)

        #expect(checkout.checkoutCount == 1)
        #expect(appModel.cart.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(appModel.selectedTab == .orders)
    }

    @Test
    func unavailableAuthenticationStillPlacesOrder() async {
        let checkout = SpyCheckoutService()
        let (viewModel, appModel) = makeSubjects(
            authResult: .unavailable,
            checkout: checkout
        )

        await viewModel.checkout(using: appModel)

        #expect(checkout.checkoutCount == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test
    func cancelledAuthenticationPlacesNoOrderAndShowsNoError() async {
        let checkout = SpyCheckoutService()
        let (viewModel, appModel) = makeSubjects(
            authResult: .cancelled,
            checkout: checkout
        )

        await viewModel.checkout(using: appModel)

        #expect(checkout.checkoutCount == 0)
        #expect(!appModel.cart.isEmpty)
        #expect(viewModel.errorMessage == nil)
        #expect(!viewModel.isCheckingOut)
    }

    @Test
    func failedAuthenticationPlacesNoOrderAndSurfacesMessage() async {
        let checkout = SpyCheckoutService()
        let (viewModel, appModel) = makeSubjects(
            authResult: .failed("Biometrics are locked."),
            checkout: checkout
        )

        await viewModel.checkout(using: appModel)

        #expect(checkout.checkoutCount == 0)
        #expect(!appModel.cart.isEmpty)
        #expect(viewModel.errorMessage == "Biometrics are locked.")
    }

    private func makeSubjects(
        authResult: CheckoutAuthenticationResult,
        checkout: SpyCheckoutService
    ) -> (CartViewModel, AppModel) {
        let appModel = AppModel(
            authService: StubAuthService(),
            walletService: StubWalletService(),
            productImportService: StubProductImportService(),
            catalogService: StubCatalogService(),
            ordersService: StubOrdersService(),
            checkoutService: checkout,
            wishlistService: StubWishlistService()
        )
        appModel.cart.add(PreviewData.product)

        let viewModel = CartViewModel(
            authenticator: StubCheckoutAuthenticator(result: authResult)
        )
        return (viewModel, appModel)
    }
}

private struct StubCheckoutAuthenticator: CheckoutAuthenticating {
    let result: CheckoutAuthenticationResult

    func confirmCheckout(reason: String) async -> CheckoutAuthenticationResult {
        result
    }
}

private final class SpyCheckoutService: CheckoutServing, @unchecked Sendable {
    private(set) var checkoutCount = 0

    func checkout(
        items: [CartItem],
        idempotencyKey: UUID
    ) async throws -> CartCheckoutResult {
        checkoutCount += 1
        return CartCheckoutResult(
            order: PlacedVirtualOrder(
                id: UUID(),
                status: .ordered,
                totalAmount: 175,
                currencyCode: "WCN",
                estimatedDeliveryAt: nil
            ),
            items: [],
            balance: Money(amount: 25, currencyCode: "WCN"),
            idempotentReplay: false
        )
    }
}

private struct StubAuthService: AuthServing {
    func hasSession() async throws -> Bool { true }
    func currentEmail() async -> String? { nil }
    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}
    func signOut() async throws {}
}

private struct StubWalletService: WalletServing {
    func getWallet() async throws -> VirtualWallet {
        throw APIError.message("unused")
    }

    func getDailyCheckInStatus() async throws -> DailyCheckInStatus {
        throw APIError.message("unused")
    }

    func claimDailyCheckIn() async throws -> DailyCheckInStatus {
        throw APIError.message("unused")
    }
}

private struct StubProductImportService: ProductImportServing {
    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata?
    ) async throws -> ProductImportResult {
        throw APIError.message("unused")
    }

    func deleteImport(forProductID productID: UUID) async throws {}
}

private struct StubCatalogService: CatalogServing {
    func browseProducts() async throws -> [Product] { [] }
    func searchProducts(query: String) async throws -> [Product] { [] }
    func products(forBrand brand: String) async throws -> [Product] { [] }
    func listBrands() async throws -> [ProductBrand] { [] }
    func heroImage(forProductID productID: UUID) async throws -> URL? { nil }
}

private struct StubOrdersService: OrdersServing {
    func listOrders() async throws -> [VirtualOrder] { [] }
}

private struct StubWishlistService: WishlistServing {
    func contains(productID: UUID) async throws -> Bool { false }
    func add(productID: UUID) async throws {}
}
