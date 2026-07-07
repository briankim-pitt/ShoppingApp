import SwiftUI

struct BrandProductsView: View {
    @Environment(AppModel.self) private var appModel

    let selection: BrandSelection
    let transitionNamespace: Namespace.ID

    @State private var viewModel = BrandProductsViewModel()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Browsing \(selection.name)…")
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
                        .tint(Color.brandPrimary)
                    }
                    .containerRelativeFrame(.vertical)
                } else if viewModel.products.isEmpty {
                    ContentUnavailableView {
                        BrandEmptyStateLabel(
                            title: "No Products Found",
                            systemImage: "tag"
                        )
                    } description: {
                        Text("No \(selection.name) products are available right now.")
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
        .appPageTitle(verbatim: selection.name)
        .task {
            await viewModel.load(selection: selection, using: appModel)
        }
    }

    private func retry() {
        Task {
            await viewModel.retry(selection: selection, using: appModel)
        }
    }
}

#Preview {
    @Previewable @Namespace var namespace

    NavigationStack {
        BrandProductsView(
            selection: BrandSelection(name: "Wooting", categoryID: nil),
            transitionNamespace: namespace
        )
    }
    .environment(PreviewData.readyAppModel)
}
