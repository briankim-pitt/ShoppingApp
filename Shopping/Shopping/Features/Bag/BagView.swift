import SwiftUI

struct BagView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Your Bag Is Empty", systemImage: "bag")
            } description: {
                Text("Products you plan to check out will appear here.")
            }
            .navigationTitle("Bag")
        }
    }
}

#Preview {
    BagView()
}
