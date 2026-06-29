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
                        .listRowBackground(Color.clear)
                    }

                    if let correctedQuery = viewModel.correctedQuery {
                        Section {
                            Label(
                                "Showing results for \(correctedQuery)",
                                systemImage: "text.magnifyingglass"
                            )
                            .foregroundStyle(.secondary)
                        }
                        .brandListRow()
                    }

                    if viewModel.hasSearchedProducts,
                       viewModel.products.isEmpty,
                       viewModel.errorMessage == nil,
                       !viewModel.isSearchingProducts {
                        Section {
                            ContentUnavailableView {
                                BrandEmptyStateLabel(
                                    title: "No Results",
                                    systemImage: "magnifyingglass"
                                )
                            } description: {
                                Text("Try another product or brand.")
                            }
                        }
                        .brandListRow()
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
                                        appModel.cart.add(product)
                                    }
                                )
                            }
                        }
                        .brandListRow()
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
                        .listRowBackground(Color.clear)
                    }

                    if let result = viewModel.result {
                        ProductImportResultView(
                            result: result,
                            isInCart: appModel.cart.contains(
                                productID: result.product.id
                            ),
                            addToCart: {
                                appModel.cart.add(result.product)
                            }
                        )
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    SearchErrorView(message: errorMessage)
                }
            }
            .brandPageBackground()
            .appPageTitle("Discover")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.mode == .products {
                        Button(
                            "Search",
                            systemImage: "magnifyingglass",
                            action: searchProducts
                        )
                        .tint(Color.brandPrimary)
                        .disabled(!viewModel.canSearchProducts)
                    } else {
                        Button(
                            "Import",
                            systemImage: "square.and.arrow.down",
                            action: importProduct
                        )
                        .tint(Color.brandPrimary)
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
