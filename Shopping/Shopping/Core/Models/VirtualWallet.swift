import Foundation

struct VirtualWallet: Codable, Equatable, Sendable {
    let balance: Money
    let homeCurrencySelected: Bool
    let homeCurrencySelectedAt: Date?

    enum CodingKeys: String, CodingKey {
        case balance
        case homeCurrencySelected = "home_currency_selected"
        case homeCurrencySelectedAt = "home_currency_selected_at"
    }
}
