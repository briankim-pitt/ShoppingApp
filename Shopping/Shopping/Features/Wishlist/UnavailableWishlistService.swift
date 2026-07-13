import Foundation

struct UnavailableWishlistService: WishlistServing {
    func listProducts() async throws -> [Product] {
        throw APIError.message(
            "Wishlists are unavailable because the app is not configured."
        )
    }

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

    func remove(productID: UUID) async throws {
        throw APIError.message(
            "Wishlists are unavailable because the app is not configured."
        )
    }
}
