import SwiftUI

struct OrderDetailHeroView: View {
    let order: VirtualOrder
    let selectedItemID: UUID?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: heroItem?.imageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "shippingbox")
                    .font(.largeTitle)
                    .foregroundStyle(Color.brandPrimary)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(Color.white.opacity(0.95))
            .clipShape(.rect(cornerRadius: 28))

            LinearGradient(
                colors: [.clear, .black.opacity(0.58)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(.rect(cornerRadius: 28))

            VStack(alignment: .leading, spacing: 8) {
                Label(order.status.title, systemImage: order.status.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))

                Text(heroItem?.title ?? "Virtual Order")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .lineLimit(3)
            }
            .padding(20)
        }
        .accessibilityElement(children: .combine)
    }

    private var heroItem: VirtualOrderItem? {
        order.items.first(where: { $0.id == selectedItemID })
            ?? order.items.first
    }
}
