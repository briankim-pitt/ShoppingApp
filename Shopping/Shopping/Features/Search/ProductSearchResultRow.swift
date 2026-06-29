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

                Label {
                    Text(product.wanderCoinPriceText)
                } icon: {
                    WanderCoinIcon(size: 16)
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.brandPrimary)

                Text("\(product.priceText) · \(product.sourceDomain)")
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
            .tint(Color.brandPrimary)
            .disabled(isInCart)
        }
        .padding(.vertical, 4)
    }
}
