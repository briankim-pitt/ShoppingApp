import Foundation

struct UnavailableWishlistService: WishlistServing {
    func contains(productID: UUID) async throws -> Bool {
        throw APIError.message(
            "Wishlists are unavailable because the app is not configured."
        )
    }

    func add(productID: UUID) async throws {
        throw APIError.message(
            "Wishlists are unavailable because the app is not configured."
        )
    }
}
