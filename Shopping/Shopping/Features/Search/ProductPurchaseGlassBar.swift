import SwiftUI

struct ProductPurchaseGlassBar: View {
    let priceText: String
    let isInCart: Bool
    let isInWishlist: Bool
    let isSavingToWishlist: Bool
    let addToCart: () -> Void
    let addToWishlist: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label {
                Text(priceText)
            } icon: {
                WanderCoinIcon(size: 18)
            }
            .bold()
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .glassEffect(.regular)

            Spacer(minLength: 0)

            Button(
                isInWishlist ? "Saved to Wishlist" : "Add to Wishlist",
                systemImage: wishlistSystemImage,
                action: addToWishlist
            )
            .labelStyle(.iconOnly)
            .frame(width: 44, height: 44)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .tint(isInWishlist ? Color.brandPrimary : nil)
            .disabled(isInWishlist || isSavingToWishlist)

            Button(
                isInCart ? "Added to Cart" : "Add to Cart",
                systemImage: isInCart ? "checkmark" : "cart.badge.plus",
                action: addToCart
            )
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(Color.brandPrimary)
            .disabled(isInCart)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private var wishlistSystemImage: String {
        if isSavingToWishlist {
            "clock"
        } else if isInWishlist {
            "heart.fill"
        } else {
            "heart"
        }
    }
}
