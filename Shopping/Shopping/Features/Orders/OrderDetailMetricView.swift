import SwiftUI

struct OrderDetailMetricView: View {
    let title: LocalizedStringKey
    let value: String
    var systemImage: String? = nil
    var showsCoin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showsCoin {
                WanderCoinIcon(size: 18)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(Color.brandPrimary)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .orderItemCardStyle()
        .accessibilityElement(children: .combine)
    }
}
