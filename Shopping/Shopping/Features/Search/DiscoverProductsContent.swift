import SwiftUI

struct DiscoverProductsContent: View {
    @Bindable var viewModel: SearchViewModel
    let cart: CartStore
    @Binding var showsAllPopular: Bool
    @Binding var showsAllRecommended: Bool
    let selectCategory: (ProductSearchCategory) -> Void

    var body: some View {
        ProductCategoryCarousel(
            selectedCategory: viewModel.selectedCategory,
            isDisabled: viewModel.isSearchingProducts,
            selectCategory: selectCategory
        )

        if viewModel.isSearchingProducts {
            ProgressView("Finding something fun…")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        }

        if let correctedQuery = viewModel.correctedQuery {
            Label(
                "Showing results for \(correctedQuery)",
                systemImage: "text.magnifyingglass"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        if viewModel.hasSearchedProducts,
           viewModel.products.isEmpty,
           viewModel.errorMessage == nil,
           !viewModel.isSearchingProducts {
            ContentUnavailableView {
                BrandEmptyStateLabel(
                    title: "No Results",
                    systemImage: "magnifyingglass"
                )
            } description: {
                Text("Try another product, brand, or category.")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }

        if !viewModel.popularProducts.isEmpty {
            DiscoverProductSection(
                title: "Popular Right Now",
                products: viewModel.popularProducts,
                collapsedCount: 2,
                showsAll: $showsAllPopular,
                cart: cart
            )
        }

        if !viewModel.recommendedProducts.isEmpty {
            DiscoverProductSection(
                title: "Recommended for You",
                products: viewModel.recommendedProducts,
                collapsedCount: 4,
                showsAll: $showsAllRecommended,
                cart: cart
            )
        }
    }
}
