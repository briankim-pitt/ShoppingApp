# Push Notifications

This document describes the planned push notification architecture. Push
delivery is not implemented yet.

## Recommended Stack

Use Apple Push Notification service (APNs) directly with:

- Swift `UserNotifications` APIs for permission and device registration.
- Supabase Postgres for devices, preferences, and delivery history.
- Supabase Queues for durable notification events.
- A Supabase Edge Function as the APNs delivery worker.
- Supabase Cron to invoke the worker regularly.

Firebase Cloud Messaging is not required while the app is iOS-only.

## Event Flow

```text
Domain transaction
    -> enqueue notification event
    -> commit transaction
    -> Cron invokes push worker
    -> worker reads a batch from Supabase Queue
    -> worker loads recipient devices and preferences
    -> worker sends each notification to APNs
    -> success: delete or archive queue message
    -> temporary failure: leave message for retry
    -> invalid token: disable device and complete message
```

Do not send notifications inline from friend-request or order APIs. External
network calls can fail or time out after the database transaction has already
succeeded. Enqueuing the event inside the transaction keeps the user action
fast and makes notification delivery retryable.

## Initial Notification Types

Start with notifications that communicate meaningful state changes:

| Type | Recipient | Deep-link destination |
| --- | --- | --- |
| `friend_request_received` | Request recipient | Incoming friend request |
| `friend_request_accepted` | Original requester | Friend profile |
| `order_shipped` | Order owner | Order tracking |
| `order_out_for_delivery` | Order owner | Order tracking |
| `order_delivered` | Order owner | Delivered order |

Do not notify for minor order stages such as `processing`. Product
recommendations can be added later after the recommendation system has clear
quality and frequency limits.

## Database Design

### `push_devices`

Store one row per app installation. A user can have multiple devices.

```sql
create table public.push_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  token text not null,
  platform text not null default 'ios',
  apns_environment text not null check (
    apns_environment in ('sandbox', 'production')
  ),
  bundle_id text not null,
  enabled boolean not null default true,
  last_seen_at timestamptz not null default now(),
  invalidated_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (token, apns_environment, bundle_id)
);
```

Only the authenticated user should be able to register, refresh, or disable
their own device. The APNs token should never be accepted for a different user
without reassigning the existing installation safely.

### `notification_preferences`

```sql
create table public.notification_preferences (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  friend_requests_enabled boolean not null default true,
  friend_acceptances_enabled boolean not null default true,
  shipping_updates_enabled boolean not null default true,
  recommendations_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
```

The worker must check preferences before sending. System-level notification
permission remains controlled by iOS.

### `push_delivery_attempts`

Store operational history without storing APNs credentials:

```sql
create table public.push_delivery_attempts (
  id bigint generated always as identity primary key,
  event_id uuid not null,
  device_id uuid references public.push_devices (id) on delete set null,
  notification_type text not null,
  attempt_number integer not null,
  apns_status integer,
  apns_id text,
  error_reason text,
  attempted_at timestamptz not null default now()
);
```

Retain this table long enough to diagnose missed or duplicated notifications,
then prune old rows with Cron.

## Queue Messages

Use a durable queue named `push_notifications`. Keep messages small:

```json
{
  "event_id": "60718509-b8bf-4c58-b047-a4caf82dd437",
  "type": "friend_request_received",
  "recipient_user_id": "fbba9d18-35c0-459d-a399-d8725cf9c9ea",
  "actor_user_id": "bd2ab7d0-ecf7-40e6-8ef0-f4fdcf275553",
  "entity_id": "8bdcd6f2-b112-4755-9b6a-58d064742130",
  "created_at": "2026-06-29T00:00:00Z"
}
```

Generate the user-facing title and body in the worker from trusted database
state. Do not place private profile, order, or product data in queue messages.

`event_id` is the idempotency key. Record completed events so the worker can
avoid sending the same logical notification twice after a retry.

## APNs Payload

Keep payloads below Apple's 4 KB limit:

```json
{
  "aps": {
    "alert": {
      "title": "New friend request",
      "body": "Alex sent you a friend request."
    },
    "sound": "default"
  },
  "type": "friend_request_received",
  "entity_id": "8bdcd6f2-b112-4755-9b6a-58d064742130"
}
```

Use custom fields only for routing. The app should fetch current server data
after opening the notification.

For shipping updates, set an APNs collapse identifier based on the order ID so
newer tracking updates can replace stale pending notifications.

## APNs Authentication

Use token-based APNs authentication with an Apple `.p8` key. Store these only
as Supabase secrets:

```text
APNS_KEY_ID
APNS_TEAM_ID
APNS_PRIVATE_KEY
APNS_BUNDLE_ID
```

Never place the private key in the Swift project, repository, database, or
client-visible environment variables.

The worker creates an ES256 provider JWT and reuses it for less than one hour.
Use the APNs sandbox host for Debug builds and the production host for
TestFlight and App Store builds.

## Delivery And Retry Rules

Handle APNs responses explicitly:

| Result | Action |
| --- | --- |
| `200` | Record success and complete the message |
| `410`, `BadDeviceToken`, `Unregistered` | Disable the device token |
| `429` | Retry with exponential backoff |
| `500`-`599` | Retry with exponential backoff |
| Other permanent `400` errors | Record failure and archive the message |

Set a maximum attempt count. Move repeatedly failing messages to an archive or
dead-letter table for inspection instead of retrying forever.

The worker should process a limited batch per invocation and use the queue
visibility timeout to prevent concurrent workers from handling the same
message.

## Swift App Responsibilities

Create a main-actor `NotificationManager` responsible for:

1. Reading the current notification authorization status.
2. Asking for permission after onboarding at a contextually useful moment.
3. Calling `UIApplication.shared.registerForRemoteNotifications()`.
4. Receiving the APNs device token through the app delegate.
5. Sending the current token and environment to `register-push-device`.
6. Retrying registration after transient failures.
7. Handling foreground presentation.
8. Routing notification taps to the correct tab and detail screen.

Register with APNs each time the app launches. Apple may change a device token
after restoring, reinstalling, or moving to another device. Forward the latest
token to the backend rather than treating a locally cached token as permanent.

On sign-out, disable that installation's token before clearing the Supabase
session. On the next sign-in, register it for the new authenticated user.

## Edge Functions

Planned functions:

| Function | Purpose |
| --- | --- |
| `register-push-device` | Upsert the current installation token |
| `disable-push-device` | Disable an installation during sign-out |
| `process-push-notifications` | Consume queued events and call APNs |

`register-push-device` and `disable-push-device` require an authenticated user.
The processing function must be callable only by the scheduled backend worker,
not by normal app users.

## Event Producers

Enqueue events from the same transaction that changes domain state:

- `send_friend_request` enqueues `friend_request_received`.
- `respond_to_friend_request` enqueues `friend_request_accepted`.
- Order shipping transitions enqueue the three selected tracking events.

Queue insertion and the domain write must commit or roll back together.

## Testing Checklist

1. Enable Push Notifications and Background Modes in Xcode.
2. Verify the `aps-environment` entitlement for Debug and Release.
3. Test on a signed physical device.
4. Confirm token registration after every launch and sign-in.
5. Confirm one user can register multiple devices.
6. Send test payloads with Apple's Push Notifications Console.
7. Test foreground, background, terminated, and notification-tap behavior.
8. Test sandbox and production APNs environments separately.
9. Simulate APNs `410`, `429`, and `500` responses.
10. Confirm invalid tokens are disabled and transient failures retry.
11. Confirm notification preferences suppress queue delivery.
12. Confirm event retries do not produce duplicate visible notifications.

## Implementation Order

1. Add APNs capability, app delegate token handling, and `NotificationManager`.
2. Add device and preference tables with RLS.
3. Implement device registration Edge Functions.
4. Enable Supabase Queues and enqueue friend events.
5. Implement the APNs worker and delivery-attempt logging.
6. Schedule the worker with Supabase Cron.
7. Add shipping events.
8. Add settings UI, deep links, and observability.

## References

- [Apple: Registering with APNs](https://developer.apple.com/documentation/usernotifications/registering-your-app-with-apns)
- [Apple: Remote notification provider server](https://developer.apple.com/documentation/usernotifications/setting-up-a-remote-notification-server)
- [Apple: Remote notification payloads](https://developer.apple.com/documentation/usernotifications/generating-a-remote-notification)
- [Supabase Queues](https://supabase.com/docs/guides/queues)
- [Consuming queue messages with Edge Functions](https://supabase.com/docs/guides/queues/consuming-messages-with-edge-functions)
- [Supabase Cron](https://supabase.com/docs/guides/cron)
