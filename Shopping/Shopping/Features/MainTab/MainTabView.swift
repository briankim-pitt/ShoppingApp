import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.selectedTab) {
            Tab(value: MainTab.home) {
                HomeView()
            } label: {
                MainTabLabel(
                    tab: .home,
                    isSelected: appModel.selectedTab == .home
                )
            }

            Tab(value: MainTab.friends) {
                FriendsView()
            } label: {
                MainTabLabel(
                    tab: .friends,
                    isSelected: appModel.selectedTab == .friends
                )
            }

            Tab(value: MainTab.orders) {
                OrdersView()
            } label: {
                MainTabLabel(
                    tab: .orders,
                    isSelected: appModel.selectedTab == .orders
                )
            }

            Tab(value: MainTab.cart) {
                CartView()
            } label: {
                MainTabLabel(
                    tab: .cart,
                    isSelected: appModel.selectedTab == .cart
                )
            }

            Tab(value: MainTab.search) {
                SearchView()
            } label: {
                MainTabLabel(
                    tab: .search,
                    isSelected: appModel.selectedTab == .search
                )
            }
        }
        .tint(Color.brandPrimary)
        .sensoryFeedback(
            .impact(weight: .medium),
            trigger: appModel.selectedTab
        )
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
