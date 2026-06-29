import Foundation

struct UnavailableCheckoutService: CheckoutServing {
    func checkout(
        items: [CartItem],
        idempotencyKey: UUID
    ) async throws -> CartCheckoutResult {
        throw ConfigurationError.missingSupabaseURL
    }
}
