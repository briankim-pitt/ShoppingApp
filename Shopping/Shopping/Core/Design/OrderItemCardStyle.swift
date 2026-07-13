import SwiftUI

private struct OrderItemCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.035), radius: 14, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.brandPrimary.opacity(0.08))
            }
    }
}

extension View {
    func orderItemCardStyle() -> some View {
        modifier(OrderItemCardModifier())
    }

    func orderItemListRow() -> some View {
        listRowInsets(
            EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
