import Testing
@testable import Shopping

@MainActor
struct CartWishlistTests {
    @Test
    func loadsExistingWishlistProductsForCart() async {
        let appModel = PreviewData.readyAppModel
        let viewModel = CartViewModel()

        await viewModel.loadWishlist(using: appModel)

        #expect(viewModel.hasLoadedWishlist)
        #expect(viewModel.wishlistProducts.count == 2)
    }

    @Test
    func saveForLaterMovesCartItemIntoWishlistResults() async {
        let appModel = PreviewData.readyAppModel
        let viewModel = CartViewModel()
        let product = PreviewData.product
        appModel.cart.add(product)

        await viewModel.loadWishlist(using: appModel)
        let item = appModel.cart.items[0]
        await viewModel.saveForLater(item, using: appModel)

        #expect(!appModel.cart.contains(productID: product.id))
        #expect(viewModel.wishlistProducts.contains { $0.id == product.id })
    }

    @Test
    func moveToCartRemovesProductFromWishlistResults() async {
        let appModel = PreviewData.readyAppModel
        let viewModel = CartViewModel()
        await viewModel.loadWishlist(using: appModel)
        let product = viewModel.wishlistProducts[0]

        await viewModel.moveToCart(product, using: appModel)

        #expect(appModel.cart.contains(productID: product.id))
        #expect(!viewModel.wishlistProducts.contains { $0.id == product.id })
    }
}
