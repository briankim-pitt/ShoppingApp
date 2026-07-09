import Foundation
import Observation

/// Persists the products a user has recently opened, most-recent first, so the
/// Home tab can surface them across launches. Entirely on-device — no backend.
@MainActor
@Observable
final class RecentlyViewedStore {
    private(set) var products: [Product] = []

    private let maxItems = 12
    private let storageKey = "recentlyViewedProducts"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func record(_ product: Product) {
        products.removeAll { $0.id == product.id }
        products.insert(product, at: 0)
        if products.count > maxItems {
            products = Array(products.prefix(maxItems))
        }
        persist()
    }

    func clear() {
        products = []
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode([Product].self, from: data)
        else { return }

        products = stored
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(products) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
