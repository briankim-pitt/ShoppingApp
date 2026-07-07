# Local Development Commands

Run these commands from the repository root unless noted otherwise.

## Supabase

Start the local Supabase stack:

```bash
npx supabase start
```

Check local service URLs, keys, and stopped containers:

```bash
npx supabase status
```

Stop the local stack while preserving local database data:

```bash
npx supabase stop
```

Apply all migrations and seed data to a fresh local database:

```bash
npx supabase db reset
```

`db reset` recreates the local database. Use it when you want a clean schema
and seed state.

Confirm migrations match the local database schema:

```bash
npx supabase db diff
```

List local migration history:

```bash
npx supabase migration list --local
```

Run a SQL query against the local database:

```bash
npx supabase db query "select now();"
```

Serve Edge Functions with a local env file:

```bash
npx supabase functions serve --env-file supabase/.env.local
```

Restart Supabase if the managed Edge Runtime is not running:

```bash
npx supabase stop
npx supabase start
```

## iOS App

Build the app for the iOS Simulator:

```bash
xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping \
  -destination 'generic/platform=iOS Simulator' build
```

List available simulators:

```bash
xcrun simctl list devices available
```

Run tests on an available simulator:

```bash
xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

Open the project in Xcode:

```bash
open Shopping/Shopping.xcodeproj
```

## Local Device Testing

Find the Mac Wi-Fi address used by an iPhone on the same network:

```bash
ipconfig getifaddr en0
```

See `docs/LOCAL_DEVICE_TESTING.md` for the current Debug Supabase URL and
physical-device checklist.

## Worker

Install worker dependencies:

```bash
npm install --prefix worker
```

Run worker tests:

```bash
npm test --prefix worker
```
