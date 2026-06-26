import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                HomeView()
            }

            Tab("Orders", systemImage: "shippingbox", value: .orders) {
                OrdersView()
            }

            Tab("Search", systemImage: "magnifyingglass", value: .search, role: .search) {
                SearchView()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(PreviewData.readyAppModel)
}
