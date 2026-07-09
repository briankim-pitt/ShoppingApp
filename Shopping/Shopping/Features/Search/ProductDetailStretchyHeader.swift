import SwiftUI

struct ProductDetailStretchyHeader: View {
    let imageURL: URL?
    let height: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("productDetailScroll")).minY
            let stretch = max(offset, 0)
            let parallax = offset < 0 ? -offset * 0.38 : -offset

            ProductDetailHeaderImage(url: imageURL)
                .frame(
                    width: proxy.size.width,
                    height: height + stretch
                )
                .offset(y: parallax)
        }
        .frame(height: height)
        .clipped()
        .accessibilityHidden(true)
    }
}
