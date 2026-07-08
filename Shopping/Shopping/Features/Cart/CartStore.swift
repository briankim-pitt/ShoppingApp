import Foundation
import Observation

@MainActor
@Observable
final class CartStore {
    private(set) var items: [CartItem] = []
    private(set) var revision = UUID()

    var itemCount: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var isEmpty: Bool {
        items.isEmpty
    }

    func contains(productID: UUID) -> Bool {
        items.contains { $0.id == productID }
    }

    func add(_ product: Product, quantity: Int = 1) {
        let clampedQuantity = min(max(quantity, 1), 99)

        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items[index].quantity = min(
                items[index].quantity + clampedQuantity,
                99
            )
        } else {
            items.append(
                CartItem(
                    product: product,
                    quantity: clampedQuantity,
                    manualCoinAmount: nil
                )
            )
        }
        recordMutation()
    }

    func setQuantity(_ quantity: Int, for productID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == productID }) else {
            return
        }
        items[index].quantity = min(max(quantity, 1), 99)
        recordMutation()
    }

    func setManualCoinPrice(_ price: Decimal?, for productID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == productID }) else {
            return
        }
        items[index].manualCoinAmount = price?.roundedUpToWholeCoin
        recordMutation()
    }

    func remove(productID: UUID) {
        items.removeAll { $0.id == productID }
        recordMutation()
    }

    func clear() {
        guard !items.isEmpty else { return }
        items.removeAll()
        recordMutation()
    }

    func total() -> Decimal? {
        guard !items.isEmpty,
              items.allSatisfy(\.isReady) else {
            return nil
        }

        return items.reduce(Decimal.zero) { total, item in
            total + (item.lineTotal ?? 0)
        }
    }

    func canCheckout() -> Bool {
        total() != nil
    }

    private func recordMutation() {
        revision = UUID()
    }
}
