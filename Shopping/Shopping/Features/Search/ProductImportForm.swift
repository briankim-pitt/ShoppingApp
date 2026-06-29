import SwiftUI

struct ProductImportForm: View {
    @Bindable var viewModel: SearchViewModel
    let importAction: () -> Void

    var body: some View {
        Section {
            TextField("https://store.com/product", text: $viewModel.productURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocorrectionDisabled()

            Button("Import Product", systemImage: "square.and.arrow.down", action: importAction)
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canImport)
        } header: {
            Text("Product URL")
        } footer: {
            Text("Paste a product link to pull in the title, image, store, and price when the site exposes it.")
        }
        .brandListRow()
    }
}
