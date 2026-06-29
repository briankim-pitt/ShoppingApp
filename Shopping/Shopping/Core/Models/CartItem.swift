import Foundation

struct CartItem: Equatable, Identifiable, Sendable {
    let product: Product
    var quantity: Int
    var manualPriceAmount: Decimal?
    var manualCurrencyCode: String?

    var id: UUID {
        product.id
    }

    var unitPrice: Decimal? {
        product.priceAmount ?? manualPriceAmount
    }

    var currencyCode: String? {
        product.currencyCode ?? manualCurrencyCode
    }

    var lineTotal: Decimal? {
        unitPrice.map { $0 * Decimal(quantity) }
    }

    func isReady(homeCurrencyCode: String) -> Bool {
        guard let unitPrice, unitPrice > 0 else { return false }
        return currencyCode?.uppercased() == homeCurrencyCode.uppercased()
    }
}
