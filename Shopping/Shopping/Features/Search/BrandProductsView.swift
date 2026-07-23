import SwiftUI

struct BrandProductsView: View {
    @Environment(AppModel.self) private var appModel

    let brand: ProductBrand
    let transitionNamespace: Namespace.ID

    @State private var viewModel = BrandProductsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading {
                    AppLoadingIndicator("Browsing \(brand.name)…", size: 32)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView {
                        BrandEmptyStateLabel(
                            title: "Couldn't Load Products",
                            systemImage: "wifi.exclamationmark"
                        )
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button(
                            "Try Again",
                            systemImage: "arrow.clockwise",
                            action: retry
                        )
                        .buttonStyle(.glassProminent)
                        .tint(Color.brandAction)
                    }
                    .containerRelativeFrame(.vertical)
                } else if viewModel.products.isEmpty {
                    ContentUnavailableView {
                        BrandEmptyStateLabel(
                            title: "No Products Found",
                            systemImage: "tag"
                        )
                    } description: {
                        Text("No \(brand.name) products are available right now.")
                    }
                    .containerRelativeFrame(.vertical)
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12),
                        ],
                        spacing: 20
                    ) {
                        ForEach(viewModel.products) { product in
                            NavigationLink(value: product) {
                                DiscoverProductCard(
                                    product: product,
                                    transitionNamespace: transitionNamespace
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.always)
        .brandPageBackground()
        .appPageTitle(verbatim: brand.name)
        .task {
            await viewModel.load(brand: brand, using: appModel)
        }
        .onChange(of: appModel.deletedImportedProductID) { _, productID in
            guard let productID else { return }
            viewModel.removeProduct(id: productID)
        }
    }

    private func retry() {
        Task {
            await viewModel.retry(brand: brand, using: appModel)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace

    NavigationStack {
        BrandProductsView(
            brand: ProductBrand(name: "Wooting", matchCount: 12),
            transitionNamespace: namespace
        )
    }
    .environment(PreviewData.readyAppModel)
}
