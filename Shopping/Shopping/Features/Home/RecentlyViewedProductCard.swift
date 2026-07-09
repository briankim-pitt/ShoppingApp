import SwiftUI

/// A fixed-size product card for the Home "Recently Viewed" carousel. Unlike
/// the grid card, the image is given an explicit square frame — a horizontal
/// scroll leaves the vertical axis unspecified, which would otherwise collapse
/// `ProductHeroImage`'s aspect-ratio sizing to a sliver.
struct RecentlyViewedProductCard: View {
    let product: Product
    let transitionNamespace: Namespace.ID

    private let cardWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProductHeroImage(url: product.imageURL)
                .frame(width: cardWidth, height: cardWidth)
                .matchedTransitionSource(
                    id: product.id,
                    in: transitionNamespace
                )

            if let brand = product.brand {
                Text(brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(product.title)
                .font(.subheadline)
                .lineLimit(2)

            Label {
                Text(product.wanderCoinPriceText)
            } icon: {
                WanderCoinIcon(size: 16)
            }
            .font(.subheadline)
            .bold()
            .foregroundStyle(Color.brandPrimary)
        }
        .frame(width: cardWidth, alignment: .leading)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
