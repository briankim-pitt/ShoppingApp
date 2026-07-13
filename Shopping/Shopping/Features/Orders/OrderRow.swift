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
        // Cast the shadow from the background shape rather than the whole row
        // so scrolling doesn't re-rasterize the thumbnail image each frame.
        .background {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.035), radius: 14, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brandPrimary.opacity(0.08))
        }
        .accessibilityElement(children: .combine)
    }
}
