import SwiftUI

struct ProductSearchForm: View {
    @Bindable var viewModel: SearchViewModel
    let searchAction: () -> Void

    var body: some View {
        Section {
            TextField("Product or brand", text: $viewModel.productQuery)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(searchAction)

            Button(
                "Search Catalog",
                systemImage: "magnifyingglass",
                action: searchAction
            )
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSearchProducts)
        } header: {
            Text("Product Search")
        } footer: {
            Text("Search imported products by title or brand.")
        }
        .brandListRow()
    }
}
