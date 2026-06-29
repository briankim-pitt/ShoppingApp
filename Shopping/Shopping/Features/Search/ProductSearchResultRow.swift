import SwiftUI

struct ProductSearchResultRow: View {
    let product: Product
    let isInCart: Bool
    let addToCart: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(url: product.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(3)

                Text(product.priceText)
                    .font(.subheadline)
                    .bold()

                Text(product.sourceDomain)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(
                isInCart ? "Added to Cart" : "Add to Cart",
                systemImage: isInCart ? "checkmark" : "cart.badge.plus",
                action: addToCart
            )
            .labelStyle(.iconOnly)
            .disabled(isInCart)
        }
        .padding(.vertical, 4)
    }
}
