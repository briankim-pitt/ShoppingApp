import Foundation
import SwiftUI

struct CartItemRow: View {
    let item: CartItem
    let setQuantity: (Int) -> Void
    let setManualCoinPrice: (Decimal?) -> Void
    let remove: () -> Void

    @State private var manualPriceText: String

    init(
        item: CartItem,
        setQuantity: @escaping (Int) -> Void,
        setManualCoinPrice: @escaping (Decimal?) -> Void,
        remove: @escaping () -> Void
    ) {
        self.item = item
        self.setQuantity = setQuantity
        self.setManualCoinPrice = setManualCoinPrice
        self.remove = remove
        _manualPriceText = State(
            initialValue: item.manualCoinAmount.map {
                NSDecimalNumber(decimal: $0).stringValue
            } ?? ""
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(url: item.product.imageURL)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.product.title)
                    .font(.headline)

                priceContent

                Stepper(
                    "Quantity \(item.quantity)",
                    value: Binding(
                        get: { item.quantity },
                        set: { newValue in
                            setQuantity(newValue)
                        }
                    ),
                    in: 1...99
                )
                .font(.subheadline)
                .tint(Color.brandPrimary)

                if let lineTotal = item.lineTotal {
                    Label {
                        Text(lineTotal.wanderCoinText)
                    } icon: {
                        WanderCoinIcon(size: 16)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button("Remove", systemImage: "trash", role: .destructive, action: remove)
        }
    }

    @ViewBuilder
    private var priceContent: some View {
        if item.product.wanderCoinPriceAmount == nil {
            HStack {
                TextField("WanderCoin price", text: $manualPriceText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: manualPriceText) { _, newValue in
                        setManualCoinPrice(decimal(from: newValue))
                    }

                WanderCoinIcon(size: 18)
            }

            if item.manualCoinAmount == nil {
                Text("Enter a WanderCoin price")
                    .font(.caption)
                    .foregroundStyle(Color.brandAccentCoral)
            }
        } else {
            Label {
                Text(item.product.wanderCoinPriceText)
            } icon: {
                WanderCoinIcon(size: 16)
            }
            .font(.subheadline)
            .foregroundStyle(Color.brandPrimary)
        }
    }

    private func decimal(from text: String) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter.number(from: text)?.decimalValue
    }
}
