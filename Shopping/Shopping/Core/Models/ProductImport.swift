import Foundation

struct ProductImport: Decodable, Equatable, Identifiable, Sendable {
    let id: UUID
    let userID: UUID
    let sourceURL: URL
    let canonicalURL: URL
    let sourceDomain: String
    let productID: UUID
    let status: String
    let errorMessage: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case sourceURL = "source_url"
        case canonicalURL = "canonical_url"
        case sourceDomain = "source_domain"
        case productID = "product_id"
        case status
        case errorMessage = "error_message"
        case createdAt = "created_at"
    }
}
