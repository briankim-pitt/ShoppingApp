import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SearchViewModel()
    @State private var showsAllPopular = false
    @State private var showsAllRecommended = false

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if viewModel.mode == .products {
                            DiscoverProductsContent(
                                viewModel: viewModel,
                                cart: appModel.cart,
                                showsAllPopular: $showsAllPopular,
                                showsAllRecommended: $showsAllRecommended,
                                selectCategory: searchCategory
                            )
                        } else {
                            DiscoverURLImportContent(
                                viewModel: viewModel,
                                cart: appModel.cart
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
