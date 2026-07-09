import SwiftUI

struct ProductDetailInfoSheet: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text((product.brand ?? product.sourceDomain).uppercased())
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(product.title)
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)
            }

            if let description = product.description,
               !description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("About this product")
                        .font(.headline)

                    Text(description)
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: product.canonicalURL) {
                Label(
                    "View Original Listing",
                    systemImage: "arrow.up.right.square"
                )
            }
            .font(.headline)
            .foregroundStyle(Color.brandPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 128)
        .background {
            UnevenRoundedRectangle(
                topLeadingRadius: 30,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 30,
                style: .continuous
            )
            .fill(Color(uiColor: .systemBackground))
        }
    }
}
