import SwiftUI

struct MainTabView: View {
    @State private var selection: MainTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem {
                    Image(MainTab.home.iconName(isSelected: selection == .home))
                        .renderingMode(.template)
                        .environment(\.symbolVariants, .none)
                    Text("")
                }
                .accessibilityLabel(MainTab.home.title)
                .tag(MainTab.home)

            FriendsView()
                .tabItem {
                    Image(MainTab.friends.iconName(isSelected: selection == .friends))
                        .renderingMode(.template)
                        .environment(\.symbolVariants, .none)
                    Text("")
                }
                .accessibilityLabel(MainTab.friends.title)
                .tag(MainTab.friends)

            OrdersView()
                .tabItem {
                    Image(MainTab.orders.iconName(isSelected: selection == .orders))
                        .renderingMode(.template)
                        .environment(\.symbolVariants, .none)
                    Text("")
                }
                .accessibilityLabel(MainTab.orders.title)
                .tag(MainTab.orders)

            CartView()
                .tabItem {
                    Image(MainTab.cart.iconName(isSelected: selection == .cart))
                        .renderingMode(.template)
                        .environment(\.symbolVariants, .none)
                    Text("")
                }
                .accessibilityLabel(MainTab.cart.title)
                .tag(MainTab.cart)

            SearchView()
                .tabItem {
                    Image(MainTab.search.iconName(isSelected: selection == .search))
                        .renderingMode(.template)
                        .environment(\.symbolVariants, .none)
                    Text("")
                }
                .accessibilityLabel(MainTab.search.title)
                .tag(MainTab.search)
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
