import Foundation
import SwiftUI

struct CartItemRow: View {
    let item: CartItem
    let homeCurrencyCode: String
    let setQuantity: (Int) -> Void
    let setManualPrice: (Decimal?) -> Void
    let remove: () -> Void

    @State private var manualPriceText: String

    init(
        item: CartItem,
        homeCurrencyCode: String,
        setQuantity: @escaping (Int) -> Void,
        setManualPrice: @escaping (Decimal?) -> Void,
        remove: @escaping () -> Void
    ) {
        self.item = item
        self.homeCurrencyCode = homeCurrencyCode
        self.setQuantity = setQuantity
        self.setManualPrice = setManualPrice
        self.remove = remove
        _manualPriceText = State(
            initialValue: item.manualPriceAmount.map {
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
                        set: setQuantity
                    ),
                    in: 1...99
                )
                .font(.subheadline)

                if let lineTotal = item.lineTotal,
                   item.currencyCode?.uppercased() == homeCurrencyCode {
                    Text(
                        lineTotal.formatted(
                            .currency(code: homeCurrencyCode).presentation(.narrow)
                        )
                    )
                    .font(.subheadline.weight(.semibold))
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
        if item.product.priceAmount == nil {
            HStack {
                TextField("Price", text: $manualPriceText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: manualPriceText) { _, newValue in
                        setManualPrice(decimal(from: newValue))
                    }

                Text(homeCurrencyCode)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if item.manualPriceAmount == nil {
                Text("Enter the product price")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if let currencyCode = item.product.currencyCode,
               currencyCode.uppercased() != homeCurrencyCode {
                Text("Uses \(currencyCode), but your wallet uses \(homeCurrencyCode)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } else if let currencyCode = item.product.currencyCode,
                  currencyCode.uppercased() != homeCurrencyCode {
            Text("Uses \(currencyCode), but your wallet uses \(homeCurrencyCode)")
                .font(.caption)
                .foregroundStyle(.red)
        } else {
            Text(item.product.priceText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func decimal(from text: String) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        return formatter.number(from: text)?.decimalValue
    }
}
