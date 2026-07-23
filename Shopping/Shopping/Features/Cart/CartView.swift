import SwiftUI

struct CartView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = CartViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if appModel.cart.isEmpty,
                   viewModel.hasLoadedWishlist,
                   viewModel.wishlistProducts.isEmpty {
                    ScrollView {
                        BrandedActionEmptyState(
                            imageName: "cart.symbols",
                            title: "Your Cart Is Empty",
                            description: "Looks like you haven’t added anything yet. Find something you love—without buying.",
                            actionTitle: "Discover Products",
                            actionSystemImage: "magnifyingglass",
                            action: showDiscover
                        )
                        .containerRelativeFrame(.vertical)
                    }
                    .scrollBounceBehavior(.always)
                    .brandPageBackground()
                    .refreshable {
                        await viewModel.loadWishlist(using: appModel)
                    }
                } else {
                    cartContent
                }
            }
            .appPageTitle("Cart")
            .toolbar {
                if !appModel.cart.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(
                            "Clear Cart",
                            systemImage: "trash",
                            role: .destructive
                        ) {
                            viewModel.isShowingClearConfirmation = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "Place this virtual order?",
                isPresented: $viewModel.isShowingCheckoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Place Order") {
                    Task {
                        await viewModel.checkout(using: appModel)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let total {
                    Text(
                        "Your wallet will be charged \(total.wanderCoinText). You may be asked to confirm this simulated purchase."
                    )
                }
            }
            .confirmationDialog(
                "Remove all items from your cart?",
                isPresented: $viewModel.isShowingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear Cart", role: .destructive) {
                    appModel.cart.clear()
                }
                Button("Cancel", role: .cancel) {}
            }
            .sensoryFeedback(trigger: viewModel.authenticationHaptic) { _, haptic in
                switch haptic {
                case .success:
                    .success
                case .failure:
                    .error
                case nil:
                    nil
                }
            }
            .task(id: appModel.selectedTab) {
                guard appModel.selectedTab == .cart else { return }
                await viewModel.loadWishlist(using: appModel)
            }
        }
    }

    private var total: Decimal? {
        appModel.cart.total()
    }

    private var canCheckout: Bool {
        guard let total, let wallet = appModel.wallet else { return false }
        return total <= wallet.balance.amount && !viewModel.isCheckingOut
    }

    private func showDiscover() {
        appModel.selectedTab = .search
    }

    private var cartContent: some View {
        List {
            if !appModel.cart.isEmpty {
                Section {
                    ForEach(appModel.cart.items) { item in
                        CartItemRow(
                            item: item,
                            setQuantity: {
                                appModel.cart.setQuantity($0, for: item.id)
                            },
                            setManualCoinPrice: {
                                appModel.cart.setManualCoinPrice($0, for: item.id)
                            },
                            saveForLater: {
                                Task {
                                    await viewModel.saveForLater(
                                        item,
                                        using: appModel
                                    )
                                }
                            },
                            remove: {
                                appModel.cart.remove(productID: item.id)
                            }
                        )
                        .orderItemListRow()
                    }
                }

                Section("Summary") {
                    LabeledContent("Wallet") {
                        Text(appModel.wallet?.balance.formatted ?? "Unavailable")
                    }

                    LabeledContent("Total") {
                        Text(total?.wanderCoinText ?? "Complete coin prices")
                    }

                    if let total, let wallet = appModel.wallet {
                        LabeledContent("After checkout") {
                            Text(
                                Money(
                                    amount: wallet.balance.amount - total,
                                    currencyCode: "WCN"
                                ).formatted
                            )
                        }
                        .foregroundStyle(
                            total > wallet.balance.amount
                                ? Color.brandAccentCoral
                                : Color.primary
                        )
                    }
                }
                .brandListRow()

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(Color.brandAccentCoral)
                    }
                    .brandListRow()
                }

                Section {
                    Button(action: viewModel.requestCheckout) {
                        HStack {
                            Spacer()
                            if viewModel.isCheckingOut {
                                AppLoadingIndicator(
                                    accessibilityLabel: "Placing order",
                                    size: 22
                                )
                            } else {
                                Label("Place Order", systemImage: "cart")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brandAction)
                    .disabled(!canCheckout)
                }
                .listRowBackground(Color.clear)
            }

            if viewModel.isLoadingWishlist,
               viewModel.wishlistProducts.isEmpty {
                Section("Saved for Later") {
                    HStack(spacing: 12) {
                        AppLoadingIndicator(
                            accessibilityLabel: "Loading saved products",
                            size: 20
                        )
                        Text("Loading saved products")
                            .foregroundStyle(.secondary)
                    }
                }
                .brandListRow()
            } else if !viewModel.wishlistProducts.isEmpty {
                Section("Saved for Later") {
                    ForEach(viewModel.wishlistProducts) { product in
                        WishlistProductRow(
                            product: product,
                            isInCart: appModel.cart.contains(
                                productID: product.id
                            ),
                            isWorking: viewModel.pendingWishlistProductIDs
                                .contains(product.id),
                            moveToCart: {
                                Task {
                                    await viewModel.moveToCart(
                                        product,
                                        using: appModel
                                    )
                                }
                            },
                            remove: {
                                Task {
                                    await viewModel.removeFromWishlist(
                                        product,
                                        using: appModel
                                    )
                                }
                            }
                        )
                        .orderItemListRow()
                    }
                }
            }

            if let wishlistErrorMessage = viewModel.wishlistErrorMessage {
                Section {
                    Label(
                        wishlistErrorMessage,
                        systemImage: "exclamationmark.triangle"
                    )
                    .foregroundStyle(Color.brandAccentCoral)
                }
                .brandListRow()
            }
        }
        .brandPageBackground()
        .refreshable {
            await viewModel.loadWishlist(using: appModel)
        }
    }
}

#Preview {
    CartView()
        .environment(PreviewData.cartAppModel)
}
