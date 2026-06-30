import SwiftUI

struct ProductThumbnail: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url?.upgradingToHTTPS) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            Image(systemName: "bag")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 72, height: 72)
        .background(.thinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
