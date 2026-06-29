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
        let manualPriceAmount: Decimal?
        let manualCurrencyCode: String?

        enum CodingKeys: String, CodingKey {
            case productID = "product_id"
            case quantity
            case manualPriceAmount = "manual_price_amount"
            case manualCurrencyCode = "manual_currency_code"
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
                manualPriceAmount: $0.product.priceAmount == nil
                    ? $0.manualPriceAmount
                    : nil,
                manualCurrencyCode: $0.product.currencyCode == nil
                    ? $0.manualCurrencyCode
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
