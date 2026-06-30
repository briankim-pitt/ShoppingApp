import SwiftUI

struct ProductCategoryCarousel: View {
    let selectedCategory: ProductSearchCategory
    let isDisabled: Bool
    let selectCategory: (ProductSearchCategory) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 8) {
                ForEach(ProductSearchCategory.allCases) { category in
                    ProductCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category,
                        isDisabled: isDisabled,
                        select: {
                            selectCategory(category)
                        }
                    )
                }
            }
            .padding(.vertical, 2)
        }
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .padding(.horizontal, -16)
        .scrollIndicators(.hidden)
        .accessibilityLabel("Product categories")
    }
}
