import Foundation

protocol CheckoutServing: Sendable {
    func checkout(
        items: [CartItem],
        idempotencyKey: UUID
    ) async throws -> CartCheckoutResult
}
