import SwiftUI

struct DiscoverProductsContent: View {
    @Bindable var viewModel: SearchViewModel
    let transitionNamespace: Namespace.ID

    var body: some View {
        if viewModel.isSearchingProducts {
            AppLoadingIndicator(
                accessibilityLabel: "Finding products",
                size: 32
            )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
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
                Text("Try another product or brand.")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }

        if !viewModel.hasSearchedProducts,
           viewModel.products.isEmpty,
           viewModel.errorMessage == nil,
           !viewModel.isSearchingProducts {
            ContentUnavailableView {
                BrandEmptyStateLabel(
                    title: "Catalog is Empty",
                    systemImage: "shippingbox"
                )
            } description: {
                Text(
                    "Import products from Safari or paste a product URL to build the catalog."
                )
            } actions: {
                Button(
                    "Import Product",
                    systemImage: "link",
                    action: showURLImport
                )
                .buttonStyle(.glassProminent)
                .tint(Color.brandPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }

        if !viewModel.brands.isEmpty, !viewModel.isSearchingProducts {
            BrandChipCarousel(brands: viewModel.brands)
        }

        if !viewModel.popularProducts.isEmpty {
            DiscoverProductSection(
                title: "Fresh Imports",
                products: viewModel.popularProducts,
                transitionNamespace: transitionNamespace
            )
        }

        if !viewModel.recommendedProducts.isEmpty {
            DiscoverProductSection(
                title: "More from the Catalog",
                products: viewModel.recommendedProducts,
                transitionNamespace: transitionNamespace
            )
        }
    }

    private func showURLImport() {
        viewModel.mode = .url
    }
}
