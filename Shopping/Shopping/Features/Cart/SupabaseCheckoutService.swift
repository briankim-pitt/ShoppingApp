import Foundation
import Supabase

struct SupabaseCheckoutService: CheckoutServing {
    private struct CheckoutRequest: Encodable {
        let items: [CheckoutItemRequest]
        let idempotencyKey: UUID

        enum CodingKeys: String, CodingKey {
            case items
            case idempotencyKey = "idempotency_key"
        }
    }

    private struct CheckoutItemRequest: Encodable {
        let productID: UUID
        let quantity: Int
        let manualCoinAmount: Decimal?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case quantity
            case manualCoinAmount = "manual_coin_amount"
        }
    }

    let client: SupabaseClient

    func checkout(
        items: [CartItem],
        idempotencyKey: UUID
    ) async throws -> CartCheckoutResult {
        let requestItems = items.map {
            CheckoutItemRequest(
                productID: $0.product.id,
                quantity: $0.quantity,
                manualCoinAmount: $0.product.wanderCoinPriceAmount == nil
                    ? $0.manualCoinAmount?.roundedUpToWholeCoin
                    : nil
            )
        }

        return try await client.functions.invoke(
            "checkout-cart",
            options: FunctionInvokeOptions(
                body: CheckoutRequest(
                    items: requestItems,
                    idempotencyKey: idempotencyKey
                )
            )
        )
    }
}
