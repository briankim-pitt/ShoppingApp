import Foundation

enum OrderBoardPositionStore {
    private static let storageKey = "orders.board.positions.v1"

    static func load() -> [UUID: OrderBoardPosition] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let storedPositions = try? JSONDecoder().decode(
                [String: OrderBoardPosition].self,
                from: data
              ) else {
            return [:]
        }

        return storedPositions.reduce(into: [:]) { positions, entry in
            guard let id = UUID(uuidString: entry.key) else { return }
            positions[id] = entry.value.clamped()
        }
    }

    static func save(_ positions: [UUID: OrderBoardPosition]) {
        let storedPositions = positions.reduce(into: [:]) { result, entry in
            result[entry.key.uuidString] = entry.value.clamped()
        }
        guard let data = try? JSONEncoder().encode(storedPositions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
