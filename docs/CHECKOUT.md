# Virtual Checkout

The virtual checkout backend has two layers:

1. The Edge Function authenticates and validates the HTTP request.
2. PostgreSQL performs the balance deduction and order creation in one transaction.

The iOS app must never update balances or create orders directly. All virtual
wallets and orders use WanderCoins (`WCN`). One USD maps to one WanderCoin.

## Cart Request

The iOS app uses the atomic cart endpoint:

`POST /functions/v1/checkout-cart`

```json
{
  "items": [
    {
      "product_id": "231525f8-2c65-4b6f-baf3-ddaa68958549",
      "quantity": 1,
      "manual_coin_amount": 179.99
    },
    {
      "product_id": "3ea24570-ee01-4424-b2a2-9938a8f2ab35",
      "quantity": 1
    }
  ],
  "idempotency_key": "caa7fe08-b8d3-4936-89a4-70ff815254cc"
}
```

The endpoint accepts 1-50 unique products. Each quantity must be 1-99.
`manual_coin_amount` is required when a product has no authoritative
`wandercoin_price_amount`. The legacy `manual_price_amount` field is temporarily
accepted as an alias. `manual_currency_code` is ignored.

The older single-product endpoint remains available for compatibility.

`POST /functions/v1/place-virtual-order`

```json
{
  "product_id": "231525f8-2c65-4b6f-baf3-ddaa68958549",
  "quantity": 1,
  "idempotency_key": "7da29f4f-5c2b-4e12-aac4-ad94692fd9fb",
  "manual_coin_amount": 179.99
}
```

## Checkout Sequence

1. `withSupabase({ auth: "user" })` verifies the access token.
2. Zod validates the cart size, UUIDs, quantities, and manual coin prices.
3. The Edge Function calls `public.place_virtual_cart_order` with the verified user ID.
4. PostgreSQL locks that user's profile row with `FOR UPDATE`.
5. PostgreSQL checks the idempotency key for an existing order.
6. PostgreSQL loads every product and chooses its authoritative or manual coin price.
7. PostgreSQL verifies that the order denomination is `WCN`.
8. PostgreSQL checks that the WanderCoin balance is sufficient.
10. PostgreSQL deducts the balance and inserts one order, all item snapshots, and one ledger entry.
11. The shipping trigger assigns an ETA, schedules the first transition, and records the `ordered` event.
12. PostgreSQL commits all changes together or rolls all of them back.

The row lock serializes checkouts for one user. Two simultaneous requests with
the same idempotency key result in one debit and one replayed response.

## Data Model

- `profiles.virtual_balance_amount`: current spendable WanderCoin balance.
- `profiles.virtual_balance_currency`: compatibility field locked to `WCN`.
- `products.wandercoin_price_amount`: authoritative checkout price in WanderCoins.
- `virtual_orders.idempotency_key`: prevents duplicate checkout processing.
- `virtual_orders.balance_after_amount`: balance snapshot after checkout.
- `virtual_order_items`: immutable WanderCoin price and source-price snapshots.
- `virtual_balance_transactions`: append-only audit trail for purchases, refunds, and adjustments.
- `virtual_order_status_events`: append-only shipping and delivery timeline.

See `SHIPPING_SIMULATION.md` for automatic timing and manual advancement.

## Security

Authenticated clients can read their own orders and balance history.
They cannot insert, update, or delete orders, order items, ledger entries, or
the balance columns. Only the service-role client inside the Edge Function can
execute the checkout database function.

## Responses

- `201`: a new order was created.
- `200`: the idempotency key already completed, so the existing order is returned.
- `400`: malformed JSON or an unexpected checkout error.
- `401`: no valid signed-in user.
- `404`: user profile or product not found.
- `409`: insufficient WanderCoin balance.
- `422`: invalid quantity or missing WanderCoin price.

## Local Testing

Start local Supabase, send the Bruno `Sign In` request, then send
`Checkout Cart`. Reusing its idempotency key should return the same order
without deducting the balance again. Change the idempotency key whenever the
cart contents change or the user begins a new checkout.
