import Foundation

enum OrderBoardPositionStore {
    private static let storageKey = "orders.board.positions.v1"
    private static let stackingOrderStorageKey = "orders.board.stacking-order.v1"

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

    static func loadStackingOrder() -> [UUID] {
        guard let storedIDs = UserDefaults.standard.stringArray(
            forKey: stackingOrderStorageKey
        ) else {
            return []
        }

        return storedIDs.compactMap(UUID.init(uuidString:))
    }

    static func saveStackingOrder(_ ids: [UUID]) {
        UserDefaults.standard.set(
            ids.map(\.uuidString),
            forKey: stackingOrderStorageKey
        )
    }
}
