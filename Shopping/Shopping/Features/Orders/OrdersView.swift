import SwiftUI

struct OrdersView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No Orders Yet", systemImage: "shippingbox")
            } description: {
                Text("Your virtual purchases will appear here.")
            }
            .navigationTitle("Orders")
        }
    }
}

#Preview {
    OrdersView()
}
