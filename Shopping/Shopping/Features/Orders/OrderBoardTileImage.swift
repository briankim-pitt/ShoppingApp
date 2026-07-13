import SwiftUI

struct OrderBoardTileImage: View {
    let item: VirtualOrderItem

    var body: some View {
        AsyncImage(url: item.imageURL) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "shippingbox")
                .font(.title)
                .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.94))
        .clipShape(.rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.8), lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: 20))
    }
}
