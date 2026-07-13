import Foundation

enum OrderBoardVisibilityStore {
    private static let storageKey = "orders.board.visibility.v1"

    static func load() -> OrderBoardVisibility {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let visibility = try? JSONDecoder().decode(
                OrderBoardVisibility.self,
                from: data
              ) else {
            return OrderBoardVisibility()
        }
        return visibility
    }

    static func save(_ visibility: OrderBoardVisibility) {
        guard let data = try? JSONEncoder().encode(visibility) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
