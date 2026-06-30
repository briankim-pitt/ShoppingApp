import SwiftUI

struct DiscoverURLImportContent: View {
    @Bindable var viewModel: SearchViewModel
    let cart: CartStore

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
                DiscoverProductCard(
                    product: result.product,
                    isInCart: cart.contains(productID: result.product.id),
                    addToCart: {
                        cart.add(result.product)
                    }
                )
                .frame(maxWidth: 220)
            }
        }
    }
}
