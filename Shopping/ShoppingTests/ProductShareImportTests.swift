import Foundation
import Testing
@testable import Shopping

@MainActor
struct ProductShareImportTests {
    @Test
    func incomingShareImportURLQueuesProductURL() throws {
        let appModel = AppModel(
            authService: UnavailableAuthService(),
            walletService: UnavailableWalletService(),
            productImportService: UnavailableProductImportService(),
            productSearchService: UnavailableProductSearchService(),
            ordersService: UnavailableOrdersService(),
            checkoutService: UnavailableCheckoutService(),
            wishlistService: UnavailableWishlistService()
        )
        let productURL = try #require(
            URL(string: "https://example.com/products/keyboard?variant=white")
        )
        var callbackComponents = URLComponents()
        callbackComponents.scheme = "shopping"
        callbackComponents.host = "import-product"
        callbackComponents.queryItems = [
            URLQueryItem(name: "url", value: productURL.absoluteString),
        ]

        let callbackURL = try #require(callbackComponents.url)
        appModel.handleIncomingURL(callbackURL)

        #expect(appModel.selectedTab == .search)
        #expect(appModel.pendingProductImport?.url == productURL)
        #expect(appModel.consumePendingProductImport()?.url == productURL)
        #expect(appModel.pendingProductImport == nil)
    }

    @Test
    func unrelatedIncomingURLIsIgnored() throws {
        let appModel = AppModel(
            authService: UnavailableAuthService(),
            walletService: UnavailableWalletService(),
            productImportService: UnavailableProductImportService(),
            productSearchService: UnavailableProductSearchService(),
            ordersService: UnavailableOrdersService(),
            checkoutService: UnavailableCheckoutService(),
            wishlistService: UnavailableWishlistService()
        )

        appModel.handleIncomingURL(
            try #require(URL(string: "https://example.com/products/keyboard"))
        )

        #expect(appModel.selectedTab == .home)
        #expect(appModel.pendingProductImport == nil)
    }
}
