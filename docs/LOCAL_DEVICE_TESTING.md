# Local Physical Device Testing

The Debug build is configured to use Supabase running on the development Mac.
Release continues to use the hosted Supabase project.

## Current Configuration

```text
Mac LAN address: 10.17.199.119
Local Supabase URL: http://10.17.199.119:54321
Debug SUPABASE_URL: http://10.17.199.119:54321
Release SUPABASE_URL: hosted Supabase project
```

`Shopping/Info.plist` allows local networking and includes the iOS local
network permission description.

The reusable account credentials are stored in `.env.device-test`. That file is
ignored by Git and must remain local.

## Start The Backend

From the repository root:

```bash
npx supabase start
```

Verify the gateway and Edge Runtime:

```bash
docker ps --format '{{.Names}}' | rg ShoppingApp
```

The running containers should include:

```text
supabase_kong_ShoppingApp
supabase_auth_ShoppingApp
supabase_rest_ShoppingApp
supabase_edge_runtime_ShoppingApp
```

The local database volume is preserved by a normal `supabase stop`. Never use
`supabase stop --no-backup` unless deleting all local data is intentional.

## Run On An iPhone

1. Connect the Mac and iPhone to the same trusted Wi-Fi network.
2. Open `Shopping/Shopping.xcodeproj`.
3. Select the Shopping scheme with the Debug configuration.
4. Select the connected iPhone as the run destination.
5. Configure the development team and signing if Xcode requests it.
6. Build and run.
7. Allow the Local Network permission when iOS prompts.
8. Sign in with the account stored in `.env.device-test`.

The account has:

- Confirmed email authentication.
- Username `device_tester`.
- Display name `Device Tester`.
- An initialized WanderCoin wallet.
- A starting virtual balance of 1000 WanderCoins.

## When The Mac IP Changes

The LAN address can change after joining another network or renewing DHCP.
Find the current Wi-Fi address with:

```bash
ipconfig getifaddr en0
```

Update the Debug `SUPABASE_URL` build setting in
`Shopping/Shopping.xcodeproj/project.pbxproj`, then rebuild the app.

Do not change the Release URL.

## Edge Function Development

The managed Edge Runtime starts with local Supabase and serves functions from
`supabase/functions`.

For live function reloads or local secrets:

```bash
npx supabase functions serve --env-file supabase/.env.local
```

The eBay `search-products` function requires:

```text
EBAY_CLIENT_ID
EBAY_CLIENT_SECRET
EBAY_MARKETPLACE_ID
```

Without those values, authentication, friends, orders, checkout, shipping,
wallet, and URL import remain testable, but eBay product search returns a
configuration error.

## Troubleshooting

### The app cannot connect

- Confirm both devices are on the same Wi-Fi.
- Confirm the Mac address still matches the Debug URL.
- Allow incoming connections for Docker and the terminal in macOS Firewall.
- Confirm the iPhone granted Local Network permission under Settings.
- Open `http://10.17.199.119:54321/auth/v1/health` from Safari on the iPhone.

### Authentication works but Edge Functions fail

Confirm `supabase_edge_runtime_ShoppingApp` is running. If it was stopped by a
one-off `supabase functions serve` session, restart the local stack:

```bash
npx supabase stop
npx supabase start
```

### Release data appears instead of local data

Confirm the Xcode scheme is using Debug. Release intentionally points to hosted
Supabase.

## Security

Local Supabase binds development services to the Mac network interfaces. Use it
only on a trusted network, keep the macOS firewall enabled, and stop Supabase
when testing is finished:

```bash
npx supabase stop
```

Local development keys are not production secrets, but they should not be used
for a deployed environment.
