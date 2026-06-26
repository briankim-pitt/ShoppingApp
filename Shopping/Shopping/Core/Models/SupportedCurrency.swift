struct SupportedCurrency: Codable, Equatable, Identifiable, Sendable {
    var id: String { currencyCode }

    let currencyCode: String
    let displayName: String
    let symbol: String
    let minorUnit: Int

    enum CodingKeys: String, CodingKey {
        case currencyCode = "currency_code"
        case displayName = "display_name"
        case symbol
        case minorUnit = "minor_unit"
    }
}
