import SwiftUI

struct CartView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = CartViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if appModel.cart.isEmpty {
                    ScrollView {
                        ContentUnavailableView {
                            Label("Your Cart Is Empty", systemImage: "cart")
                        } description: {
                            Text("Products you plan to check out will appear here.")
                        }
                        .containerRelativeFrame(.vertical)
                    }
                    .scrollBounceBehavior(.always)
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
                    Text("Your virtual wallet will be charged \(total.formatted).")
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
        }
    }

    private var homeCurrencyCode: String {
        appModel.wallet?.balance.currencyCode ?? "USD"
    }

    private var total: Money? {
        appModel.cart.total(homeCurrencyCode: homeCurrencyCode).map {
            Money(amount: $0, currencyCode: homeCurrencyCode)
        }
    }

    private var canCheckout: Bool {
        guard let total, let wallet = appModel.wallet else { return false }
        return total.amount <= wallet.balance.amount && !viewModel.isCheckingOut
    }

    private var cartContent: some View {
        List {
            Section {
                ForEach(appModel.cart.items) { item in
                    CartItemRow(
                        item: item,
                        homeCurrencyCode: homeCurrencyCode,
                        setQuantity: {
                            appModel.cart.setQuantity($0, for: item.id)
                        },
                        setManualPrice: {
                            appModel.cart.setManualPrice($0, for: item.id)
                        },
                        remove: {
                            appModel.cart.remove(productID: item.id)
                        }
                    )
                }
            }

            Section("Summary") {
                LabeledContent("Wallet") {
                    Text(appModel.wallet?.balance.formatted ?? "Unavailable")
                }

                LabeledContent("Total") {
                    Text(total?.formatted ?? "Complete item prices")
                }

                if let total, let wallet = appModel.wallet {
                    LabeledContent("After checkout") {
                        Text(
                            Money(
                                amount: wallet.balance.amount - total.amount,
                                currencyCode: homeCurrencyCode
                            ).formatted
                        )
                    }
                    .foregroundStyle(
                        total.amount > wallet.balance.amount
                            ? Color.red
                            : Color.primary
                    )
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            Section {
                Button(action: viewModel.requestCheckout) {
                    HStack {
                        Spacer()
                        if viewModel.isCheckingOut {
                            ProgressView()
                        } else {
                            Label("Place Order", systemImage: "cart")
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canCheckout)
            }
            .listRowBackground(Color.clear)
        }
    }
}

#Preview {
    CartView()
        .environment(PreviewData.cartAppModel)
}
