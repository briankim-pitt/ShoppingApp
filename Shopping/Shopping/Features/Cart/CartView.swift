import SwiftUI

struct CartView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Your Cart Is Empty", systemImage: "cart")
            } description: {
                Text("Products you plan to check out will appear here.")
            }
            .appPageTitle("Cart")
        }
    }
}

#Preview {
    CartView()
}
