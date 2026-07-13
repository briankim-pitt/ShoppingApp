import SwiftUI

struct ShipmentMapMarker: View {
    let imageURL: URL?
    var imageSize: CGFloat = 38

    var body: some View {
        AsyncImage(url: imageURL?.upgradingToHTTPS) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Image(systemName: "shippingbox.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: imageSize, height: imageSize)
        .background(.white)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(.white, lineWidth: 3)
        }
        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
        .accessibilityHidden(true)
    }
}
