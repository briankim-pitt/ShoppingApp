import SwiftUI

struct OrderRow: View {
    let order: VirtualOrder

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OrderThumbnail(url: order.items.first?.imageURL)

            VStack(alignment: .leading, spacing: 4) {
                Text(order.primaryItemTitle)
                    .font(.headline)
                    .lineLimit(2)

                Label(order.status.title, systemImage: order.status.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(order.totalText)
                        .bold()

                    Spacer()

                    Text(order.orderedAt, format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
