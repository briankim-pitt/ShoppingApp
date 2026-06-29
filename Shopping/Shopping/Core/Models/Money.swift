import Foundation

struct Money: Codable, Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String

    enum CodingKeys: String, CodingKey {
        case amount
        case currencyCode = "currency_code"
    }

    var formatted: String {
        if currencyCode == "WCN" {
            return amount.wanderCoinText
        }

        return amount.formatted(
            .currency(code: currencyCode).presentation(.narrow)
        )
    }
}
