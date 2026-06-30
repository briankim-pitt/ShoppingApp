import SwiftUI

struct ProductCategoryChip: View {
    @Environment(\.accessibilityDifferentiateWithoutColor)
    private var differentiateWithoutColor

    let category: ProductSearchCategory
    let isSelected: Bool
    let isDisabled: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 6) {
                if isSelected && differentiateWithoutColor {
                    Image(systemName: "checkmark")
                }

                Text(category.title)
            }
            .font(.subheadline)
            .bold(isSelected)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background {
                Capsule()
                    .fill(isSelected ? Color.brandPrimary : Color.clear)
            }
            .overlay {
                if !isSelected {
                    Capsule()
                        .stroke(.separator, lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
