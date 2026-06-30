import SwiftUI

struct DiscoverProductCard: View {
    let product: Product
    let isInCart: Bool
    let addToCart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: product.imageURL?.upgradingToHTTPS) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Image(systemName: "bag")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(12)
                .background(
                    Color.brandPurpleSurface,
                    in: .rect(cornerRadius: 14)
                )
                .accessibilityHidden(true)

                Button(
                    isInCart ? "Added to Cart" : "Add to Cart",
                    systemImage: isInCart ? "checkmark" : "cart.badge.plus",
                    action: addToCart
                )
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: .circle)
                .tint(Color.brandPrimary)
                .disabled(isInCart)
                .padding(6)
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
        .accessibilityElement(children: .contain)
    }
}
