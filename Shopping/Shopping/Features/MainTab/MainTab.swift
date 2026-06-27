enum MainTab: CaseIterable, Hashable {
    case home
    case friends
    case orders
    case cart
    case search

    var title: String {
        switch self {
        case .home:
            "Home"
        case .friends:
            "Friends"
        case .orders:
            "Orders"
        case .cart:
            "Cart"
        case .search:
            "Search"
        }
    }

    var unselectedIconName: String {
        switch self {
        case .home:
            "mingcute_home-4-line.symbols"
        case .friends:
            "friend.symbols"
        case .orders:
            "mingcute_package-2-line.symbols"
        case .cart:
            "cart.symbols"
        case .search:
            "mingcute_search-3-line.symbols"
        }
    }

    var selectedIconName: String {
        "\(unselectedIconName).fill"
    }

    func iconName(isSelected: Bool) -> String {
        isSelected ? selectedIconName : unselectedIconName
    }
}
