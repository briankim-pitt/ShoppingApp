import SwiftUI

struct ProductImportResultView: View {
    let result: ProductImportResult

    var body: some View {
        Section("Imported Product") {
            HStack(alignment: .top, spacing: 12) {
                ProductThumbnail(url: result.product.imageURL)

                VStack(alignment: .leading, spacing: 6) {
                    Text(result.product.title)
                        .font(.headline)

                    Text(result.product.sourceDomain)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(result.product.priceText)
                        .font(.subheadline.weight(.semibold))

                    if let description = result.product.description, !description.isEmpty {
                        Text(description)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}
