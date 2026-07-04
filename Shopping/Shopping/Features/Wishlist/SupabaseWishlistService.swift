import Foundation
import Supabase

struct SupabaseWishlistService: WishlistServing {
    private struct WishlistRecord: Decodable {
        let id: UUID
    }

    private struct NewWishlist: Encodable {
        let userID: UUID
        let name: String
        let visibility: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case name
            case visibility
        }
    }

    private struct WishlistItemRecord: Decodable {
        let id: UUID
    }

    private struct NewWishlistItem: Encodable {
        let wishlistID: UUID
        let productID: UUID

        enum CodingKeys: String, CodingKey {
            case wishlistID = "wishlist_id"
            case productID = "product_id"
        }
    }

    let client: SupabaseClient

    func contains(productID: UUID) async throws -> Bool {
        guard let wishlistID = try await existingWishlistID() else {
            return false
        }

        return try await contains(
            productID: productID,
            wishlistID: wishlistID
        )
    }

    func add(productID: UUID) async throws {
        let wishlistID = try await defaultWishlistID()
        let alreadyContainsProduct = try await contains(
            productID: productID,
            wishlistID: wishlistID
        )
        guard !alreadyContainsProduct else {
            return
        }

        try await client
            .from("wishlist_items")
            .insert(
                NewWishlistItem(
                    wishlistID: wishlistID,
                    productID: productID
                )
            )
            .execute()
    }

    private func existingWishlistID() async throws -> UUID? {
        let userID = try await client.auth.session.user.id
        let wishlists: [WishlistRecord] = try await client
            .from("wishlists")
            .select("id")
            .eq("user_id", value: userID)
            .order("created_at", ascending: true)
            .limit(1)
            .execute()
            .value
        return wishlists.first?.id
    }

    private func defaultWishlistID() async throws -> UUID {
        if let wishlistID = try await existingWishlistID() {
            return wishlistID
        }

        let userID = try await client.auth.session.user.id
        let wishlists: [WishlistRecord] = try await client
            .from("wishlists")
            .insert(
                NewWishlist(
                    userID: userID,
                    name: "Wishlist",
                    visibility: "private"
                )
            )
            .select("id")
            .execute()
            .value

        guard let wishlistID = wishlists.first?.id else {
            throw APIError.message("The wishlist could not be created.")
        }
        return wishlistID
    }

    private func contains(
        productID: UUID,
        wishlistID: UUID
    ) async throws -> Bool {
        let items: [WishlistItemRecord] = try await client
            .from("wishlist_items")
            .select("id")
            .eq("wishlist_id", value: wishlistID)
            .eq("product_id", value: productID)
            .limit(1)
            .execute()
            .value
        return !items.isEmpty
    }
}
