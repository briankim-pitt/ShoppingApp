import SwiftUI

struct ProductDetailHeroImage: View {
    let url: URL?

    var body: some View {
        Color.brandPurpleSurface
            .containerRelativeFrame(.vertical) { length, _ in
                length * 0.46
            }
            .overlay {
                AsyncImage(url: url?.upgradingToHTTPS) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                } placeholder: {
                    Image(systemName: "bag")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
                .clipped()
            }
            .accessibilityHidden(true)
    }
}
