import SwiftUI

struct DiscoverSearchHeader: View {
    @Bindable var viewModel: SearchViewModel
    let searchAction: () -> Void
    let importAction: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            DiscoverSearchBar(
                text: searchText,
                mode: viewModel.mode,
                submit: submit
            )

            Menu {
                Button(
                    "Search Products",
                    systemImage: "magnifyingglass",
                    action: showProductSearch
                )

                Button(
                    "Import from URL",
                    systemImage: "link",
                    action: showURLImport
                )
            } label: {
                Label(
                    "Discover Options",
                    systemImage: "line.3.horizontal.decrease"
                )
                .labelStyle(.iconOnly)
                .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
            .tint(Color.brandPrimary)
        }
    }

    private var searchText: Binding<String> {
        if viewModel.mode == .products {
            $viewModel.productQuery
        } else {
            $viewModel.productURL
        }
    }

    private func submit() {
        if viewModel.mode == .products {
            searchAction()
        } else {
            importAction()
        }
    }

    private func showProductSearch() {
        viewModel.mode = .products
    }

    private func showURLImport() {
        viewModel.mode = .url
    }
}
