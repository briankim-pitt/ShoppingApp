import SwiftUI

struct SearchView: View {
    @State private var query = ""

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Find Products", systemImage: "magnifyingglass")
            } description: {
                if query.isEmpty {
                    Text("Search products, brands, and stores.")
                } else {
                    Text("No results for “\(query)”.")
                }
            }
            .navigationTitle("Search")
            .searchable(
                text: $query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Products, brands, and stores"
            )
        }
    }
}

#Preview {
    SearchView()
}
