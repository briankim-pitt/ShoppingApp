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
                "Search eBay",
                systemImage: "magnifyingglass",
                action: searchAction
            )
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSearchProducts)
        } header: {
            Text("Product Search")
        } footer: {
            Text("USD listings convert to WanderCoins at a 1:1 rate.")
        }
        .brandListRow()
    }
}
