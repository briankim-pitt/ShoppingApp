import SwiftUI

struct DiscoverProductCard: View {
    let product: Product
    let isInCart: Bool
    let addToCart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Color.brandPurpleSurface

                AsyncImage(url: product.imageURL?.upgradingToHTTPS) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } placeholder: {
                    Image(systemName: "bag")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(.rect(cornerRadius: 14))
            .accessibilityHidden(true)

            Text(product.title)
                .font(.subheadline)
                .lineLimit(2)

            HStack(spacing: 8) {
                Label {
                    Text(product.wanderCoinPriceText)
                } icon: {
                    WanderCoinIcon(size: 16)
                }
                .font(.subheadline)
                .bold()
                .foregroundStyle(Color.brandPrimary)

                Spacer(minLength: 0)

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
            }
        }
        .accessibilityElement(children: .contain)
    }
}
