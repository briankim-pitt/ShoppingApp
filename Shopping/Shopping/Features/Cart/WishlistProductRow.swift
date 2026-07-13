import SwiftUI

struct WishlistProductRow: View {
    let product: Product
    let isInCart: Bool
    let isWorking: Bool
    let moveToCart: () -> Void
    let remove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(url: product.imageURL)

            VStack(alignment: .leading, spacing: 7) {
                Text(product.title)
                    .font(.headline)
                    .lineLimit(2)

                if let price = product.wanderCoinPriceAmount {
                    Label {
                        Text(price.roundedUpToWholeCoin.wanderCoinNumber)
                    } icon: {
                        WanderCoinIcon(size: 15)
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.brandPrimary)
                } else {
                    Text("Set coin price in cart")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if isInCart {
                    Label("In Cart", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                } else {
                    Button(
                        "Move to Cart",
                        systemImage: "cart.badge.plus",
                        action: moveToCart
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .buttonStyle(.borderless)
                    .disabled(isWorking)
                }
            }

            Spacer(minLength: 0)

            if isWorking {
                AppLoadingIndicator(
                    accessibilityLabel: "Updating saved product",
                    size: 18
                )
            }
        }
        .orderItemCardStyle()
        .swipeActions {
            Button("Remove", systemImage: "trash", role: .destructive, action: remove)
                .disabled(isWorking)

            if !isInCart {
                Button(
                    "Move to Cart",
                    systemImage: "cart.badge.plus",
                    action: moveToCart
                )
                .tint(Color.brandPrimary)
                .disabled(isWorking)
            }
        }
    }
}
