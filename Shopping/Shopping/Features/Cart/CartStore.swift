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

    func add(_ product: Product, homeCurrencyCode: String?) {
        if let index = items.firstIndex(where: { $0.id == product.id }) {
            items[index].quantity = min(items[index].quantity + 1, 99)
        } else {
            items.append(
                CartItem(
                    product: product,
                    quantity: 1,
                    manualPriceAmount: nil,
                    manualCurrencyCode: product.currencyCode == nil
                        ? homeCurrencyCode?.uppercased()
                        : nil
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

    func setManualPrice(_ price: Decimal?, for productID: UUID) {
        guard let index = items.firstIndex(where: { $0.id == productID }) else {
            return
        }
        items[index].manualPriceAmount = price
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

    func total(homeCurrencyCode: String) -> Decimal? {
        guard !items.isEmpty,
              items.allSatisfy({ $0.isReady(homeCurrencyCode: homeCurrencyCode) }) else {
            return nil
        }

        return items.reduce(Decimal.zero) { total, item in
            total + (item.lineTotal ?? 0)
        }
    }

    func canCheckout(homeCurrencyCode: String) -> Bool {
        total(homeCurrencyCode: homeCurrencyCode) != nil
    }

    private func recordMutation() {
        revision = UUID()
    }
}
