# Shipping Simulation

Virtual orders progress through this lifecycle:

`ordered -> processing -> shipped -> out_for_delivery -> delivered`

New orders receive an estimated delivery time and a `next_status_at` timestamp.
Supabase Cron calls the due-order transition function once per minute.

## Default Timing

| Current status | Next status | Delay |
| --- | --- | --- |
| `ordered` | `processing` | 30 seconds |
| `processing` | `shipped` | 1 minute |
| `shipped` | `out_for_delivery` | 2 minutes |
| `out_for_delivery` | `delivered` | 1 minute |

The accelerated journey takes approximately 4 minutes and 30 seconds. Cron
runs once per minute, so an individual transition may happen up to one minute
after its scheduled timestamp.

## Data Model

`virtual_orders` stores:

- `processing_at`
- `shipped_at`
- `out_for_delivery_at`
- `delivered_at`
- `cancelled_at`
- `estimated_delivery_at`
- `next_status_at`

`virtual_order_status_events` is the append-only timeline used by an order
tracking interface. Authenticated users can read events only for their own
orders. Clients cannot insert or update events or order shipping fields.

## Manual Testing

Send the Bruno `Simulate Order Shipping` request:

```json
{
  "order_id": "YOUR_ORDER_ID",
  "force": true
}
```

Each request advances one stage and returns the updated order plus its complete
event timeline. The access token determines the user; an order belonging to
another user is returned as not found.

Set `force` to `false` to advance only if `next_status_at` has passed.

The endpoint returns:

- `200` when the order is returned or advanced.
- `400` for malformed JSON or another transition error.
- `401` when authentication is missing.
- `404` when the order does not belong to the authenticated user.
- `409` when the order is already delivered or cancelled.
