enum SearchMode: String, CaseIterable, Identifiable {
    case products
    case url

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .products:
            "Products"
        case .url:
            "URL"
        }
    }
}
