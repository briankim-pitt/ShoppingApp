import Foundation

struct CartItem: Equatable, Identifiable, Sendable {
    let product: Product
    var quantity: Int
    var manualCoinAmount: Decimal?

    var id: UUID {
        product.id
    }

    var unitCoinPrice: Decimal? {
        (product.wanderCoinPriceAmount ?? manualCoinAmount)?
            .roundedUpToWholeCoin
    }

    var lineTotal: Decimal? {
        unitCoinPrice.map { $0 * Decimal(quantity) }
    }

    var isReady: Bool {
        guard let unitCoinPrice else { return false }
        return unitCoinPrice > 0
    }
}
