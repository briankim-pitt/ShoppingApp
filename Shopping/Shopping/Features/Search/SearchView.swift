import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SearchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section {
                    Picker("Search Mode", selection: $viewModel.mode) {
                        ForEach(SearchMode.allCases) { mode in
                            Text(mode.title)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)

                if viewModel.mode == .products {
                    ProductSearchForm(
                        viewModel: viewModel,
                        searchAction: searchProducts
                    )

                    if viewModel.isSearchingProducts {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }

                    if let correctedQuery = viewModel.correctedQuery {
                        Section {
                            Label(
                                "Showing results for \(correctedQuery)",
                                systemImage: "text.magnifyingglass"
                            )
                            .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.hasSearchedProducts,
                       viewModel.products.isEmpty,
                       viewModel.errorMessage == nil,
                       !viewModel.isSearchingProducts {
                        Section {
                            ContentUnavailableView.search
                        }
                    }

                    if !viewModel.products.isEmpty {
                        Section("eBay Results") {
                            ForEach(viewModel.products) { product in
                                ProductSearchResultRow(
                                    product: product,
                                    isInCart: appModel.cart.contains(
                                        productID: product.id
                                    ),
                                    addToCart: {
                                        appModel.cart.add(
                                            product,
                                            homeCurrencyCode: appModel.wallet?
                                                .balance.currencyCode
                                        )
                                    }
                                )
                            }
                        }
                    }
                } else {
                    ProductImportForm(
                        viewModel: viewModel,
                        importAction: importProduct
                    )

                    if viewModel.isImporting {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }

                    if let result = viewModel.result {
                        ProductImportResultView(
                            result: result,
                            isInCart: appModel.cart.contains(
                                productID: result.product.id
                            ),
                            addToCart: {
                                appModel.cart.add(
                                    result.product,
                                    homeCurrencyCode: appModel.wallet?
                                        .balance.currencyCode
                                )
                            }
                        )
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    SearchErrorView(message: errorMessage)
                }
            }
            .appPageTitle("Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.mode == .products {
                        Button(
                            "Search",
                            systemImage: "magnifyingglass",
                            action: searchProducts
                        )
                        .disabled(!viewModel.canSearchProducts)
                    } else {
                        Button(
                            "Import",
                            systemImage: "square.and.arrow.down",
                            action: importProduct
                        )
                        .disabled(!viewModel.canImport)
                    }
                }
            }
        }
    }

    private func importProduct() {
        Task {
            await viewModel.importProduct(using: appModel)
        }
    }

    private func searchProducts() {
        Task {
            await viewModel.searchProducts(using: appModel)
        }
    }
}

#Preview {
    SearchView()
        .environment(PreviewData.readyAppModel)
}
