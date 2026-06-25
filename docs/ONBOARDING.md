# Currency Onboarding

After sign-in, the app should check the user's private wallet:

`POST /rest/v1/rpc/get_my_wallet`

If `home_currency_selected` is `false`, show the home-currency picker before
allowing checkout.

## Load The Picker

`GET /rest/v1/supported_currencies`

The response contains active currency codes, display names, symbols, and minor
units. `minor_unit` tells the app how many decimal places to display. For
example, USD uses 2 and JPY uses 0.

## Save The Choice

`POST /functions/v1/set-home-currency`

```json
{
  "currency_code": "JPY"
}
```

The endpoint:

1. Verifies the signed-in user.
2. Checks that the currency is supported and active.
3. Locks the user's profile row.
4. Rejects changes after the first virtual purchase.
5. Updates the wallet currency and records the selection time.

Users may correct the choice before their first purchase. The choice is locked
afterward so existing orders, ledger entries, and balances stay in one
consistent currency.

The starting virtual balance remains `1000` in the chosen currency. A future
onboarding step can let users choose their starting budget separately.

## Privacy

Wallet columns are not available through social profile queries. The owner
reads them through `get_my_wallet()`, which derives the user ID from the
authenticated session.
