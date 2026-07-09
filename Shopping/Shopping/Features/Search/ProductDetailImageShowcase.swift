import SwiftUI

struct ProductDetailImageShowcase: View {
    /// The thumbnail stored on the product — shows instantly.
    let thumbnailURL: URL?
    /// A higher-resolution image that fades in over the thumbnail once loaded.
    let hiResURL: URL?

    @State private var hiResImage: Image?

    var body: some View {
        ZStack {
            showcaseImage(url: thumbnailURL)

            // Layered on top and crossfaded in; the thumbnail stays mounted
            // beneath so nothing ever blanks out during the swap.
            if let hiResImage {
                hiResImage
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .accessibilityHidden(true)
        .task(id: hiResURL) {
            await loadHiResImage()
        }
    }

    private func showcaseImage(url: URL?) -> some View {
        AsyncImage(url: url?.upgradingToHTTPS) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            case .failure:
                placeholder(systemImage: "bag")
            case .empty:
                placeholder(systemImage: nil)
            @unknown default:
                placeholder(systemImage: nil)
            }
        }
    }

    private func loadHiResImage() async {
        hiResImage = nil

        guard let hiResURL, hiResURL != thumbnailURL else { return }

        // Decode fully before swapping so the crossfade begins only once the
        // sharp image is ready to paint — avoiding any flash.
        guard let uiImage = await Self.decodeImage(from: hiResURL) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.4)) {
            hiResImage = Image(uiImage: uiImage)
        }
    }

    private static func decodeImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(
                from: url.upgradingToHTTPS
            )
            return UIImage(data: data)
        } catch {
            return nil
        }
    }

    private func placeholder(systemImage: String?) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .tint(Color.brandPrimary)
                }
            }
    }
}
