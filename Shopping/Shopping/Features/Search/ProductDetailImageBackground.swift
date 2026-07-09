import SwiftUI

struct ProductDetailImageBackground: View {
    let url: URL?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(uiColor: .systemGroupedBackground)

                AsyncImage(url: url?.upgradingToHTTPS) { phase in
                    if let image = phase.image {
                        imageLayers(image, size: proxy.size)
                    }
                }

                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.58)

                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGroupedBackground)
                            .opacity(0.12),
                        Color(uiColor: .systemGroupedBackground)
                            .opacity(0.58),
                        Color(uiColor: .systemGroupedBackground)
                            .opacity(0.82),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func imageLayers(_ image: Image, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .blur(radius: 72)
                .saturation(1.25)
                .opacity(0.58)
                .clipped()

            image
                .resizable()
                .scaledToFill()
                .frame(width: size.width * 0.9, height: size.height * 0.48)
                .blur(radius: 28)
                .saturation(1.15)
                .opacity(0.36)
                .offset(y: -size.height * 0.08)
                .clipped()
        }
    }
}
