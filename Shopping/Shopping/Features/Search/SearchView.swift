import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = SearchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                ProductImportForm(
                    viewModel: viewModel,
                    importAction: importProduct
                )

                if viewModel.isImporting {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    SearchErrorView(message: errorMessage)
                }

                if let result = viewModel.result {
                    ProductImportResultView(result: result)
                }
            }
            .appPageTitle("Search")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import", systemImage: "square.and.arrow.down", action: importProduct)
                        .disabled(!viewModel.canImport)
                }
            }
        }
    }

    private func importProduct() {
        Task {
            await viewModel.importProduct(using: appModel)
        }
    }
}

#Preview {
    SearchView()
        .environment(PreviewData.readyAppModel)
}
