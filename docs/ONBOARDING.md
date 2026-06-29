# WanderCoin Wallet Initialization

Every profile receives a WanderCoin wallet automatically. New wallets start
with `1000 WCN`; no currency selection step is required.

`POST /rest/v1/rpc/get_my_wallet`

The response retains `home_currency_selected: true` and a `currency_code` of
`WCN` for compatibility with the current Swift client.

## Compatibility Endpoints

`GET /rest/v1/supported_currencies` returns one active denomination:
WanderCoins (`WCN`, symbol `W`).

`POST /functions/v1/set-home-currency` remains available while the existing
client is migrated, but only accepts:

```json
{
  "currency_code": "WCN"
}
```

Other denomination values are rejected.

## Privacy

Wallet columns remain unavailable through social profile queries. The owner
reads them through `get_my_wallet()`, which derives the user ID from the
authenticated session.
