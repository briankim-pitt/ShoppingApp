import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SearchViewModel()
    @State private var showsAllPopular = false
    @State private var showsAllRecommended = false
    @Namespace private var productTransition

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if viewModel.mode == .products {
                            DiscoverProductsContent(
                                viewModel: viewModel,
                                showsAllPopular: $showsAllPopular,
                                showsAllRecommended: $showsAllRecommended,
                                transitionNamespace: productTransition
                            )
                        } else {
                            DiscoverURLImportContent(
                                viewModel: viewModel,
                                transitionNamespace: productTransition
                            )
                        }

                        if let errorMessage = viewModel.errorMessage {
                            SearchErrorView(message: errorMessage)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 72)
                    .padding(.bottom, 32)
                }
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    await viewModel.resetToCatalog(using: appModel)
                }
                .brandPageBackground()

                DiscoverSearchHeader(
                    viewModel: viewModel,
                    searchAction: searchProducts,
                    importAction: importProduct
                )
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .appPageTitle("Discover")
            .navigationDestination(for: ProductBrand.self) { brand in
                BrandProductsView(
                    brand: brand,
                    transitionNamespace: productTransition
                )
            }
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(
                    product: product
                )
                .navigationTransition(
                    .zoom(
                        sourceID: product.id,
                        in: productTransition
                    )
                )
            }
            .task {
                await viewModel.loadInitialProducts(using: appModel)
                await importPendingProductURL()
            }
            .onChange(of: appModel.pendingProductImport) {
                Task {
                    await importPendingProductURL()
                }
            }
            .onChange(of: appModel.deletedImportedProductID) { _, productID in
                guard let productID else { return }
                viewModel.removeProduct(id: productID)
            }
        }
    }

    private func importProduct() {
        Task {
            await viewModel.importProduct(using: appModel)
        }
    }

    private func importPendingProductURL() async {
        guard let pending = appModel.consumePendingProductImport() else { return }
        await viewModel.importProduct(
            from: pending.url,
            extracted: pending.extracted,
            using: appModel
        )
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
