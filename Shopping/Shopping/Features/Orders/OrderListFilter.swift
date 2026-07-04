enum OrderListFilter: String, CaseIterable, Identifiable {
    case all
    case past

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .all:
            "All Orders"
        case .past:
            "Past Orders"
        }
    }

    func includes(_ status: VirtualOrderStatus) -> Bool {
        switch self {
        case .all:
            true
        case .past:
            status == .delivered || status == .cancelled
        }
    }
}
