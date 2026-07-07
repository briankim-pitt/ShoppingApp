import SwiftUI

struct BrandChip: View {
    let brand: ProductBrand

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "tag")
                .font(.caption)
                .foregroundStyle(Color.brandPrimary)

            Text(brand.name)
        }
        .font(.subheadline)
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .frame(minHeight: 44)
        .overlay {
            Capsule()
                .stroke(.separator, lineWidth: 1)
        }
        .contentShape(.capsule)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Browse products by this brand")
    }
}
