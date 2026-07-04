import SwiftUI

struct OrderRow: View {
    let order: VirtualOrder

    var body: some View {
        HStack(spacing: 12) {
            OrderThumbnail(url: order.items.first?.imageURL)

            VStack(alignment: .leading, spacing: 6) {
                Text(order.primaryItemTitle)
                    .font(.headline)
                    .lineLimit(2)

                Label(order.status.title, systemImage: order.status.systemImage)
                    .font(.subheadline)
                    .foregroundStyle(Color.brandPrimary)

                HStack {
                    Label {
                        Text(order.totalText)
                    } icon: {
                        WanderCoinIcon(size: 15)
                    }
                    .bold()
                    .foregroundStyle(Color.brandPrimary)
                }
                .font(.footnote)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)

                Spacer()

                Text(
                    order.orderedAt,
                    format: .dateTime.month(.abbreviated).day()
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(
            Color.brandPurpleSurface,
            in: .rect(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.brandPrimary.opacity(0.12))
        }
        .accessibilityElement(children: .combine)
    }
}
