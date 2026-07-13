import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SearchViewModel()
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
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
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newValue in
                    guard !isRefreshing else { return }
                    scrollOffset = newValue < 0 ? -newValue : 0
                }
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isRefreshing = true
                    }
                    await viewModel.resetToCatalog(using: appModel)
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isRefreshing = false
                        scrollOffset = 0
                    }
                }
                .brandPageBackground()

                DiscoverSearchHeader(
                    viewModel: viewModel,
                    searchAction: searchProducts,
                    importAction: importProduct
                )
                .padding(.horizontal)
                .padding(.top, 8)
                .opacity(searchBarOpacity)
                .allowsHitTesting(searchBarOpacity > 0.05)
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

    private var searchBarOpacity: CGFloat {
        guard !isRefreshing else { return 0 }
        return max(1 - (scrollOffset / 56), 0)
    }
}

#Preview {
    SearchView()
        .environment(PreviewData.readyAppModel)
}
