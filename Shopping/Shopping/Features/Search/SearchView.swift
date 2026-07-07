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
                                transitionNamespace: productTransition,
                                selectCategory: searchCategory
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
            .navigationDestination(for: BrandSelection.self) { selection in
                BrandProductsView(
                    selection: selection,
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

    private func searchCategory(_ category: ProductSearchCategory) {
        showsAllPopular = false
        showsAllRecommended = false

        Task {
            await viewModel.searchProducts(
                in: category,
                using: appModel
            )
        }
    }
}

#Preview {
    SearchView()
        .environment(PreviewData.readyAppModel)
}
