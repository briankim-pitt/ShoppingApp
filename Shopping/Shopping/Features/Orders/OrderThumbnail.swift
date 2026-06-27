import SwiftUI

struct OrderThumbnail: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "shippingbox")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 64, height: 64)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}
