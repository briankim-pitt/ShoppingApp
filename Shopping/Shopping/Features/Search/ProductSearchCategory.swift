import Foundation

enum ProductSearchCategory: String, CaseIterable, Identifiable {
    case all
    case fashion
    case tech
    case home
    case beauty

    var id: Self { self }

    var title: String {
        switch self {
        case .all:
            "All"
        case .fashion:
            "Fashion"
        case .tech:
            "Tech"
        case .home:
            "Home"
        case .beauty:
            "Beauty"
        }
    }

    var searchQuery: String {
        switch self {
        case .all:
            "iphone"
        case .fashion:
            "fashion"
        case .tech:
            "electronics"
        case .home:
            "home decor"
        case .beauty:
            "beauty"
        }
    }
}
