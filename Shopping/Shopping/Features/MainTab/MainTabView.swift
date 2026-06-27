import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab(value: MainTab.home) {
                HomeView()
            } label: {
                MainTabLabel(
                    tab: .home,
                    isSelected: selection == .home
                )
            }

            Tab(value: MainTab.friends) {
                FriendsView()
            } label: {
                MainTabLabel(
                    tab: .friends,
                    isSelected: selection == .friends
                )
            }

            Tab(value: MainTab.orders) {
                OrdersView()
            } label: {
                MainTabLabel(
                    tab: .orders,
                    isSelected: selection == .orders
                )
            }

            Tab(value: MainTab.cart) {
                CartView()
            } label: {
                MainTabLabel(
                    tab: .cart,
                    isSelected: selection == .cart
                )
            }

            Tab(value: MainTab.search) {
                SearchView()
            } label: {
                MainTabLabel(
                    tab: .search,
                    isSelected: selection == .search
                )
            }
        }
        .tint(.primary)
    }
}

#Preview("Light") {
    MainTabView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    MainTabView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.dark)
}
