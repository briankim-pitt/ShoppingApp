import SwiftUI

struct OrderItemRow: View {
    let item: VirtualOrderItem

    var body: some View {
        HStack(spacing: 12) {
            OrderThumbnail(url: item.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                Text("Quantity \(item.quantity)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Label {
                    Text(item.totalPriceText)
                } icon: {
                    WanderCoinIcon(size: 15)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
