import SwiftUI

struct CurrencyRow: View {
    let currency: SupportedCurrency
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(currency.symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.quaternary, in: .rect(cornerRadius: 8))
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(currency.displayName)
                Text(currency.currencyCode)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
