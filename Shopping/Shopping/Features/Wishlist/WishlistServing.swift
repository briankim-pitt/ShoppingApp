import Foundation

protocol WishlistServing: Sendable {
    func listProducts() async throws -> [Product]
    func contains(productID: UUID) async throws -> Bool
    func add(productID: UUID) async throws
    func remove(productID: UUID) async throws
}
