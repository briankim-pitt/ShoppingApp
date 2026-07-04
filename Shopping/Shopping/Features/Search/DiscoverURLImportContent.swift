import SwiftUI

struct DiscoverURLImportContent: View {
    @Bindable var viewModel: SearchViewModel
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import from URL")
                .font(.headline)

            Text(
                "Paste a product link above, then press Search on the keyboard."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if viewModel.isImporting {
                ProgressView("Importing product…")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            }

            if let result = viewModel.result {
                NavigationLink(value: result.product) {
                    DiscoverProductCard(
                        product: result.product,
                        transitionNamespace: transitionNamespace
                    )
                }
                .buttonStyle(.plain)
                .frame(maxWidth: 220)
            }
        }
    }
}
