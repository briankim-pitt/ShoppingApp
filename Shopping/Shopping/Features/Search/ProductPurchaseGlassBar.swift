import SwiftUI

struct ProductPurchaseGlassBar: View {
    let priceText: String
    let quantity: Int
    let isInCart: Bool
    let decrementQuantity: () -> Void
    let incrementQuantity: () -> Void
    let addToCart: () -> Void
    let undoAddToCart: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                pricePill
                quantityPill
            }

            HStack(spacing: 12) {
                addToCartButton
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var pricePill: some View {
        Label {
            Text(priceText)
        } icon: {
            WanderCoinIcon(size: 18)
        }
        .bold()
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .glassEffect(.regular)
    }

    private var quantityPill: some View {
        HStack(spacing: 12) {
            Button(
                "Decrease Quantity",
                systemImage: "minus",
                action: decrementQuantity
            )
            .labelStyle(.iconOnly)
            .frame(width: 36, height: 36)
            .buttonStyle(.plain)
            .contentShape(.circle)
            .disabled(quantity <= 1)
            .accessibilityLabel("Decrease quantity")

            Text("\(quantity)")
                .font(.headline.monospacedDigit())
                .frame(minWidth: 24)
                .accessibilityLabel("Quantity \(quantity)")

            Button(
                "Increase Quantity",
                systemImage: "plus",
                action: incrementQuantity
            )
            .labelStyle(.iconOnly)
            .frame(width: 36, height: 36)
            .buttonStyle(.plain)
            .contentShape(.circle)
            .disabled(quantity >= 99)
            .accessibilityLabel("Increase quantity")
        }
        .font(.headline)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .glassEffect(.regular)
    }

    private var addToCartButton: some View {
        Button(action: addToCart) {
            Text(isInCart ? "Added to Cart" : "Add to Cart")
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(Color.brandAction)
        .disabled(isInCart)
        .overlay(alignment: .trailing) {
            if isInCart {
                Button(
                    "Undo Add to Cart",
                    systemImage: "arrow.uturn.backward",
                    action: undoAddToCart
                )
                .labelStyle(.iconOnly)
                .frame(width: 52, height: 52)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .padding(.trailing, 6)
            }
        }
    }
}
