import Foundation

protocol WishlistServing: Sendable {
    func contains(productID: UUID) async throws -> Bool
    func add(productID: UUID) async throws
}
