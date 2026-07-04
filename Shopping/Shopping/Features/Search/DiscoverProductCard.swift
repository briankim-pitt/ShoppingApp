import SwiftUI

struct DiscoverProductCard: View {
    let product: Product
    let transitionNamespace: Namespace.ID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProductHeroImage(url: product.imageURL)
                .matchedTransitionSource(
                    id: product.id,
                    in: transitionNamespace
                )

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
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
