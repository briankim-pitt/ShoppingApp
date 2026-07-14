import SwiftUI

struct OrderDetailHeroView: View {
    let order: VirtualOrder
    let selectedItemID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ProductHeroImage(url: heroItem?.imageURL)
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.brandPrimary.opacity(0.08))
                }
                .shadow(color: .black.opacity(0.035), radius: 14, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Label(order.status.title, systemImage: order.status.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)

                Text(heroItem?.title ?? "Virtual Order")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .lineLimit(3)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var heroItem: VirtualOrderItem? {
        order.items.first(where: { $0.id == selectedItemID })
            ?? order.items.first
    }
}
