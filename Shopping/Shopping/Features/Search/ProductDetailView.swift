import SwiftUI

struct ProductDetailView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isInWishlist = false
    @State private var isSavingToWishlist = false
    @State private var wishlistErrorMessage = ""
    @State private var isShowingWishlistError = false

    let product: Product

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ProductDetailHeroImage(url: product.imageURL)

                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.title)
                            .font(.title2)
                            .bold()

                        Text(product.sourceDomain)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Source price: \(product.priceText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let description = product.description,
                       !description.isEmpty {
                        Divider()

                        Text("About this product")
                            .font(.headline)

                        Text(description)
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: product.canonicalURL) {
                        Label(
                            "View Original Listing",
                            systemImage: "arrow.up.right.square"
                        )
                    }
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding()
                .padding(.bottom, 96)
            }
        }
        .ignoresSafeArea(edges: .top)
        .brandPageBackground()
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: product.id) {
            await loadWishlistState()
        }
        .alert(
            "Couldn’t Update Wishlist",
            isPresented: $isShowingWishlistError
        ) {
        } message: {
            Text(wishlistErrorMessage)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ProductPurchaseGlassBar(
                priceText: product.wanderCoinPriceText,
                isInCart: isInCart,
                isInWishlist: isInWishlist,
                isSavingToWishlist: isSavingToWishlist,
                addToCart: addToCart,
                addToWishlist: addToWishlist
            )
        }
    }

    private var isInCart: Bool {
        appModel.cart.contains(productID: product.id)
    }

    private func addToCart() {
        appModel.cart.add(product)
    }

    private func loadWishlistState() async {
        isInWishlist = (try? await appModel.isInWishlist(
            productID: product.id
        )) ?? false
    }

    private func addToWishlist() {
        guard !isInWishlist, !isSavingToWishlist else { return }
        isSavingToWishlist = true

        Task {
            defer { isSavingToWishlist = false }

            do {
                try await appModel.addToWishlist(productID: product.id)
                isInWishlist = true
            } catch {
                wishlistErrorMessage = error.localizedDescription
                isShowingWishlistError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProductDetailView(
            product: PreviewData.product
        )
    }
    .environment(PreviewData.readyAppModel)
}
