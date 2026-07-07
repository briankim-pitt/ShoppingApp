import SwiftUI

struct BrandChipCarousel: View {
    let brands: [ProductBrand]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Shop by Brand")
                .font(.headline)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 8) {
                    ForEach(brands) { brand in
                        NavigationLink(value: brand) {
                            BrandChip(brand: brand)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .padding(.horizontal, -16)
            .scrollIndicators(.hidden)
            .accessibilityLabel("Brands")
        }
    }
}
