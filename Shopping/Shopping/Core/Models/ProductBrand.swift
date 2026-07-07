struct ProductBrand: Decodable, Equatable, Hashable, Identifiable, Sendable {
    let name: String
    let matchCount: Int?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case matchCount = "match_count"
    }
}
