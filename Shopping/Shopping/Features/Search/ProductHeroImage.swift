import SwiftUI

struct ProductHeroImage: View {
    let url: URL?

    var body: some View {
        Color.brandPurpleSurface
            .aspectRatio(1, contentMode: .fit)
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
            .clipShape(.rect(cornerRadius: 14))
            .accessibilityHidden(true)
    }
}
