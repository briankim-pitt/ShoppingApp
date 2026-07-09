import SwiftUI

struct ProductDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @State private var isInWishlist = false
    @State private var isSavingToWishlist = false
    @State private var wishlistErrorMessage = ""
    @State private var isShowingWishlistError = false
    @State private var isDeletingImport = false
    @State private var deleteImportErrorMessage = ""
    @State private var isShowingDeleteImportError = false
    @State private var isShowingDeleteConfirmation = false
    @State private var containerSize: CGSize = .zero
    @State private var quantity = 1
    @State private var hiResImageURL: URL?

    let product: Product

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    ProductDetailImageShowcase(
                        thumbnailURL: product.imageURL,
                        hiResURL: hiResImageURL
                    )

                    ProductDetailInfoSheet(product: product)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 20)
                .frame(
                    maxWidth: containerSize.width > 0
                        ? containerSize.width
                        : nil
                )
            }
            .scrollIndicators(.hidden)
        }
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            containerSize = size
        }
        .background {
            Color(uiColor: .systemGroupedBackground)
            NavigationBarTopBlurDisabler()
        }
        .scrollContentBackground(.hidden)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarBackground(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                wishlistToolbarButton
            }

            ToolbarItem(placement: .topBarTrailing) {
                deleteImportToolbarButton
            }
        }
        .task(id: product.id) {
            appModel.recentlyViewed.record(product)
            async let wishlistState: Void = loadWishlistState()
            async let heroImage: Void = loadHiResImage()
            _ = await (wishlistState, heroImage)
        }
        .alert(
            "Couldn’t Update Wishlist",
            isPresented: $isShowingWishlistError
        ) {
        } message: {
            Text(wishlistErrorMessage)
        }
        .alert(
            "Couldn’t Delete Import",
            isPresented: $isShowingDeleteImportError
        ) {
        } message: {
            Text(deleteImportErrorMessage)
        }
        .confirmationDialog(
            "Delete this import?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Import", role: .destructive) {
                deleteImport()
            }

            Button("Cancel", role: .cancel) {
            }
        } message: {
            Text("This removes the imported product from your catalog.")
        }
        .overlay(alignment: .bottom) {
            ProductPurchaseGlassBar(
                priceText: totalPriceText,
                quantity: quantity,
                isInCart: isInCart,
                decrementQuantity: decrementQuantity,
                incrementQuantity: incrementQuantity,
                addToCart: addToCart,
                undoAddToCart: undoAddToCart
            )
            .padding(.bottom, 8)
        }
    }

    private var isInCart: Bool {
        appModel.cart.contains(productID: product.id)
    }

    private var totalPriceText: String {
        guard let unitPrice = product.wanderCoinPriceAmount else {
            return "Set coin price in cart"
        }

        return (unitPrice.roundedUpToWholeCoin * Decimal(quantity))
            .wanderCoinText
    }

    private var wishlistToolbarButton: some View {
        Button("Add to Wishlist", systemImage: wishlistSystemImage) {
            addToWishlist()
        }
        .labelStyle(.iconOnly)
        .tint(isInWishlist ? Color.brandPrimary : nil)
        .disabled(isInWishlist || isSavingToWishlist)
        .accessibilityLabel(
            isInWishlist ? "Saved to Wishlist" : "Add to Wishlist"
        )
    }

    private var wishlistSystemImage: String {
        if isSavingToWishlist {
            "clock"
        } else if isInWishlist {
            "heart.fill"
        } else {
            "heart"
        }
    }

    private var deleteImportToolbarButton: some View {
        Button(
            isDeletingImport ? "Deleting Import" : "Delete Import",
            systemImage: "trash",
            role: .destructive,
            action: showDeleteConfirmation
        )
        .labelStyle(.iconOnly)
        .disabled(isDeletingImport)
    }

    private func addToCart() {
        appModel.cart.add(product, quantity: quantity)
    }

    private func undoAddToCart() {
        appModel.cart.remove(productID: product.id)
    }

    private func decrementQuantity() {
        quantity = max(quantity - 1, 1)
    }

    private func incrementQuantity() {
        quantity = min(quantity + 1, 99)
    }

    private func showDeleteConfirmation() {
        guard !isDeletingImport else { return }
        isShowingDeleteConfirmation = true
    }

    private func deleteImport() {
        guard !isDeletingImport else { return }
        isDeletingImport = true

        Task {
            defer { isDeletingImport = false }

            do {
                try await appModel.deleteImport(forProductID: product.id)
                dismiss()
            } catch {
                deleteImportErrorMessage = error.localizedDescription
                isShowingDeleteImportError = true
            }
        }
    }

    private func loadWishlistState() async {
        isInWishlist = (try? await appModel.isInWishlist(
            productID: product.id
        )) ?? false
    }

    private func loadHiResImage() async {
        // A failure just leaves the thumbnail showing; the showcase never
        // blanks out waiting for this.
        hiResImageURL = try? await appModel.heroImage(forProductID: product.id)
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
