import SwiftUI

struct ProductDetailHeroImage: View {
    let url: URL?
    let title: String
    let eyebrow: String
    let subtitle: String?
    let containerSize: CGSize

    @State private var loadedImage: UIImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let loadedImage {
                heroBackdrop(loadedImage)
            } else {
                Color(uiColor: .systemGroupedBackground)
            }

            VStack(spacing: 0) {
                if let loadedImage {
                    loadedImageContent(loadedImage)
                } else {
                    placeholderContent
                        .frame(height: imageHeight)
                }

                titleContent
            }
        }
        .frame(height: heroHeight)
        .frame(width: imageWidth)
        .clipped()
        .task(id: url) {
            await loadImage()
        }
    }

    private var layout: HeroImageLayout.Layout {
        HeroImageLayout.layout(
            imageSize: loadedImage?.size ?? .zero,
            containerWidth: containerSize.width,
            containerHeight: containerSize.height
        )
    }

    private var heroHeight: CGFloat {
        guard containerSize != .zero else { return 360 }
        return layout.height
    }

    private var imageHeight: CGFloat {
        max(heroHeight - titleHeight, 1)
    }

    private var titleHeight: CGFloat {
        min(max(heroHeight * 0.28, 136), 188)
    }

    private var imageWidth: CGFloat {
        max(containerSize.width, 1)
    }

    private func heroBackdrop(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth, height: heroHeight)
            .blur(radius: 34)
            .saturation(1.12)
            .overlay {
                LinearGradient(
                    colors: [
                        .white.opacity(0.2),
                        .black.opacity(0.1),
                        .black.opacity(0.32),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .accessibilityHidden(true)
    }

    private func loadedImageContent(_ image: UIImage) -> some View {
        ZStack(alignment: .top) {
            switch layout.mode {
            case .topAlignedFill:
                topAlignedImage(image)
            case .fitOverBackdrop:
                fitImageOverBackdrop(image)
            }
        }
        .frame(height: imageHeight)
        .clipped()
        .accessibilityHidden(true)
    }

    private func topAlignedImage(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: imageWidth)
            .frame(height: imageHeight, alignment: .top)
            .clipped()
    }

    private func fitImageOverBackdrop(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
    }

    private var placeholderContent: some View {
        Color(uiColor: .systemGroupedBackground)
            .overlay {
                if didFail {
                    Image(systemName: "bag")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .tint(Color.brandPrimary)
                }
            }
            .accessibilityHidden(true)
    }

    private var titleContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(3)
                .minimumScaleFactor(0.82)

            if let subtitle,
               !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: titleHeight, alignment: .bottomLeading)
        .frame(width: imageWidth, alignment: .leading)
        .background {
            LinearGradient(
                colors: [
                    .black.opacity(0.02),
                    .black.opacity(0.34),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .accessibilityElement(children: .combine)
    }

    private func loadImage() async {
        withAnimation(.snappy) {
            loadedImage = nil
            didFail = false
        }

        guard let url else {
            withAnimation(.snappy) {
                loadedImage = nil
                didFail = true
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(
                from: url.upgradingToHTTPS
            )
            guard let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }

            withAnimation(.snappy) {
                loadedImage = image
                didFail = false
            }
        } catch {
            withAnimation(.snappy) {
                loadedImage = nil
                didFail = true
            }
        }
    }
}

#Preview("Catalog Product") {
    ProductDetailHeroImage(
        url: PreviewData.product.imageURL,
        title: PreviewData.product.title,
        eyebrow: (PreviewData.product.brand ?? PreviewData.product.sourceDomain)
            .uppercased(),
        subtitle: PreviewData.product.description,
        containerSize: CGSize(width: 393, height: 852)
    )
}

#Preview("Portrait Product") {
    ProductDetailHeroImage(
        url: URL(
            string: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f"
        ),
        title: "Longline Wool Coat",
        eyebrow: "ATELIER",
        subtitle: "A tailored portrait product image that should keep the head visible.",
        containerSize: CGSize(width: 393, height: 852)
    )
}
