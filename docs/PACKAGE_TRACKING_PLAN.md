# Execution Plan: Simulated Package Tracking Map (MapKit)

Goal: add a simulated package-tracking map to the Orders feature. Every virtual
order gets a shipping route (origin warehouse → destination city) stored in the
database. The iOS app shows a MapKit map in `OrderDetailView` with the route,
origin/destination markers, and a package marker that moves along the route as
the existing shipping simulation advances (`ordered → processing → shipped →
out_for_delivery → delivered`, see `docs/SHIPPING_SIMULATION.md`).

This plan is prescriptive. Follow the phases in order. Read every file listed
in "Read first" before writing code in that phase, and match the surrounding
style exactly.

## Ground rules

- iOS 26+, Swift 6 strict concurrency, SwiftUI only (no UIKit views). Use the
  `swiftui-pro` skill (`.agents/skills/swiftui-pro/SKILL.md`) to review all new
  SwiftUI code before finishing.
- The package position is **derived, not streamed**: the client interpolates
  between origin and destination using timestamps the backend already
  maintains. Do NOT add polling endpoints, realtime channels, or a
  location-updating cron job.
- No new third-party dependencies. MapKit and CoreLocation are system
  frameworks.
- Do not modify `worker/` (product scraper — unrelated) or `QueueMe/`
  (separate app). Only `supabase/`, `Shopping/`, `docs/`, and optionally
  `bruno/` change.
- Clients must never be able to write route columns. Reads ride the existing
  `virtual_orders` RLS select policy; do not grant `update` to `authenticated`.

## How the simulation maps to the route

| Status | Package position |
| --- | --- |
| `ordered`, `processing` | at origin (fraction 0) |
| `shipped`, `out_for_delivery` | fraction of elapsed time between `shipped_at` and `estimated_delivery_at`, clamped to `0...1` |
| `delivered` | at destination (fraction 1) |
| `cancelled` | no map shown |

`shipped_at`, `estimated_delivery_at`, and `delivered_at` already exist on
`virtual_orders` and in the Swift `VirtualOrder` model — reuse them.

---

## Phase 1 — Database migration

**Read first:** `supabase/migrations/20260627072353_simulate_shipping_delivery.sql`
(style reference: `private.*` trigger functions, `security invoker`,
`set search_path = ''`, explicit revokes) and
`supabase/migrations/20260624070412_initial_schema.sql` lines 135–150.

Create `supabase/migrations/<timestamp>_add_package_tracking_route.sql`.
Generate the timestamp with `date +%Y%m%d%H%M%S` (UTC-style, matching existing
filenames). Contents, in order:

### 1a. Columns

```sql
alter table public.virtual_orders
add column origin_name text,
add column origin_latitude double precision,
add column origin_longitude double precision,
add column destination_name text,
add column destination_latitude double precision,
add column destination_longitude double precision;
```

### 1b. Deterministic route picker

One private helper so the trigger and the backfill share logic. Pick from a
fixed list of ~8 world locations, seeded by the order id so results are stable
and clients can't influence them. Origin and destination must differ.

```sql
create or replace function private.virtual_order_route(p_order_id uuid)
returns table (
  origin_name text,
  origin_latitude double precision,
  origin_longitude double precision,
  destination_name text,
  destination_latitude double precision,
  destination_longitude double precision
)
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  v_locations constant jsonb := jsonb_build_array(
    jsonb_build_object('name', 'Seattle Fulfillment Center', 'lat', 47.6062, 'lng', -122.3321),
    jsonb_build_object('name', 'Los Angeles Hub', 'lat', 34.0522, 'lng', -118.2437),
    jsonb_build_object('name', 'Chicago Depot', 'lat', 41.8781, 'lng', -87.6298),
    jsonb_build_object('name', 'New York Warehouse', 'lat', 40.7128, 'lng', -74.0060),
    jsonb_build_object('name', 'London Hub', 'lat', 51.5074, 'lng', -0.1278),
    jsonb_build_object('name', 'Berlin Depot', 'lat', 52.5200, 'lng', 13.4050),
    jsonb_build_object('name', 'Tokyo Fulfillment Center', 'lat', 35.6762, 'lng', 139.6503),
    jsonb_build_object('name', 'Sydney Warehouse', 'lat', -33.8688, 'lng', 151.2093)
  );
  v_count constant integer := jsonb_array_length(v_locations);
  v_seed bigint := abs(hashtextextended(p_order_id::text, 0));
  v_origin_index integer := (v_seed % v_count)::integer;
  v_destination_index integer :=
    ((v_seed / v_count + 1 + v_origin_index) % v_count)::integer;
begin
  if v_destination_index = v_origin_index then
    v_destination_index := (v_origin_index + 1) % v_count;
  end if;

  return query select
    v_locations -> v_origin_index ->> 'name',
    (v_locations -> v_origin_index ->> 'lat')::double precision,
    (v_locations -> v_origin_index ->> 'lng')::double precision,
    v_locations -> v_destination_index ->> 'name',
    (v_locations -> v_destination_index ->> 'lat')::double precision,
    (v_locations -> v_destination_index ->> 'lng')::double precision;
end;
$$;

revoke all on function private.virtual_order_route(uuid)
from public, anon, authenticated, service_role;
```

### 1c. Trigger to assign the route on insert

Do NOT edit `private.prepare_virtual_order_shipping()` — add a separate
before-insert trigger so all order-creation paths (`place-virtual-order`,
`checkout-cart` RPCs) are covered without touching them:

```sql
create or replace function private.assign_virtual_order_route()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_route record;
begin
  if new.origin_latitude is not null then
    return new;
  end if;

  select * into v_route from private.virtual_order_route(new.id);

  new.origin_name = v_route.origin_name;
  new.origin_latitude = v_route.origin_latitude;
  new.origin_longitude = v_route.origin_longitude;
  new.destination_name = v_route.destination_name;
  new.destination_latitude = v_route.destination_latitude;
  new.destination_longitude = v_route.destination_longitude;

  return new;
end;
$$;

revoke all on function private.assign_virtual_order_route()
from public, anon, authenticated, service_role;

create trigger virtual_orders_assign_route
before insert on public.virtual_orders
for each row
execute function private.assign_virtual_order_route();
```

### 1d. Backfill existing orders

```sql
update public.virtual_orders virtual_order
set
  origin_name = route.origin_name,
  origin_latitude = route.origin_latitude,
  origin_longitude = route.origin_longitude,
  destination_name = route.destination_name,
  destination_latitude = route.destination_latitude,
  destination_longitude = route.destination_longitude
from lateral private.virtual_order_route(virtual_order.id) route
where virtual_order.origin_latitude is null;
```

### 1e. What NOT to change

- No new grants or policies: `authenticated` already has select on
  `virtual_orders`, and has no update grant — keep it that way.
- `public.advance_virtual_order_shipping` returns `to_jsonb(v_order)`, so the
  new columns flow through the `simulate-order-shipping` edge function
  automatically. No edge-function changes are needed in
  `supabase/functions/`.

### Verify Phase 1

```sh
supabase start          # if not already running
supabase db reset       # applies all migrations + seed.sql
```

Then confirm with `psql` (or `supabase db diff` should be empty):
place an order via the Bruno collection (`bruno/tests/Place Virtual Order.yml`
or `Checkout Cart.yml`) and check the row has non-null route columns and
`origin_name <> destination_name`. Also run
`bruno/tests/Simulate Order Shipping.yml` and confirm the response `order`
object includes the six new fields.

---

## Phase 2 — Swift model + service

**Read first:** `Shopping/Shopping/Core/Models/VirtualOrder.swift`,
`Shopping/Shopping/Features/Orders/SupabaseOrdersService.swift`,
`Shopping/Shopping/PreviewSupport/PreviewData.swift`.

1. **`VirtualOrder.swift`** — add six optional stored properties with matching
   coding keys, keeping the existing ordering style:
   `originName: String?`, `originLatitude: Double?`, `originLongitude: Double?`,
   `destinationName: String?`, `destinationLatitude: Double?`,
   `destinationLongitude: Double?` (snake_case keys `origin_name`, etc.).
   Do not import CoreLocation here — `Core/Models` stays framework-free.

2. **`SupabaseOrdersService.swift`** — add the six column names to the select
   string (after `next_status_at`, before `created_at`).

3. **New file `Shopping/Shopping/Features/Orders/ShipmentRoute.swift`** — the
   feature-side tracking logic. Import CoreLocation only. Sketch:

   ```swift
   import CoreLocation
   import Foundation

   struct ShipmentRoute: Equatable, Sendable {
       let originName: String
       let origin: CLLocationCoordinate2D
       let destinationName: String
       let destination: CLLocationCoordinate2D
   }
   ```

   Add `extension CLLocationCoordinate2D: @retroactive Equatable` only if the
   compiler requires it; otherwise store raw lat/lng doubles and expose
   computed `CLLocationCoordinate2D` values — prefer whichever keeps
   `Equatable` conformance warning-free under Swift 6.

   In the same file (or `VirtualOrder+ShipmentTracking.swift` if it grows past
   ~100 lines), extend `VirtualOrder`:

   ```swift
   extension VirtualOrder {
       var shipmentRoute: ShipmentRoute? {
           // nil unless all six fields are present; nil when status == .cancelled
       }

       /// 0 at origin, 1 at destination.
       func shipmentProgress(at date: Date) -> Double {
           // ordered/processing -> 0; delivered -> 1
           // shipped/outForDelivery:
           //   guard let shippedAt, let estimatedDeliveryAt,
           //         estimatedDeliveryAt > shippedAt else fall back to 0 / 1
           //   fraction = date.timeIntervalSince(shippedAt)
           //            / estimatedDeliveryAt.timeIntervalSince(shippedAt)
           //   clamp to 0...1
       }
   }
   ```

4. **New file `Shopping/Shopping/Features/Orders/ShipmentGeometry.swift`** —
   pure math so it is unit-testable and the marker always sits on the drawn
   path. Great-circle (slerp) interpolation:

   ```swift
   enum ShipmentGeometry {
       /// Great-circle interpolation between two coordinates, t in 0...1.
       static func coordinate(
           from start: CLLocationCoordinate2D,
           to end: CLLocationCoordinate2D,
           fraction t: Double
       ) -> CLLocationCoordinate2D

       /// `sampleCount` evenly spaced points from start to end (inclusive),
       /// built with `coordinate(from:to:fraction:)`. Default 64.
       static func routeCoordinates(
           from start: CLLocationCoordinate2D,
           to end: CLLocationCoordinate2D,
           sampleCount: Int = 64
       ) -> [CLLocationCoordinate2D]
   }
   ```

   Slerp formula (angles in radians; φ = latitude, λ = longitude):
   - `d = 2 * asin(sqrt(sin²((φ2−φ1)/2) + cos(φ1)·cos(φ2)·sin²((λ2−λ1)/2)))`
   - If `d` is ~0, return `start`. Clamp `t` to `0...1`.
   - `a = sin((1−t)·d) / sin(d)`, `b = sin(t·d) / sin(d)`
   - `x = a·cos(φ1)·cos(λ1) + b·cos(φ2)·cos(λ2)`
   - `y = a·cos(φ1)·sin(λ1) + b·cos(φ2)·sin(λ2)`
   - `z = a·sin(φ1) + b·sin(φ2)`
   - `φ = atan2(z, sqrt(x² + y²))`, `λ = atan2(y, x)` → convert back to degrees.

5. **`PreviewData.swift`** — `VirtualOrder` has a memberwise initializer, so
   every `VirtualOrder(...)` call site must gain the six new arguments. Give
   the preview orders a real route (e.g. Seattle → Tokyo) so previews show the
   map; the `.shipped` preview order already has `shippedAt`/
   `estimatedDeliveryAt` straddling `.now`, which puts the marker mid-route.

### Verify Phase 2

```sh
xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping \
  -destination 'generic/platform=iOS Simulator' build
```

Build must succeed with zero new warnings.

---

## Phase 3 — MapKit UI

**Read first:** `Shopping/Shopping/Features/Orders/OrderDetailView.swift`,
`OrderTrackingTimeline.swift`, `OrderTrackingStepView.swift`, and
`Shopping/Shopping/Core/Design/` (brand modifiers like `brandListRow()` /
`brandPageBackground()`). Consult `.agents/skills/swiftui-pro/references/`
(`views.md`, `design.md`, `accessibility.md`) while writing.

1. **New file `Shopping/Shopping/Features/Orders/OrderTrackingMapView.swift`**:

   ```swift
   import MapKit
   import SwiftUI

   struct OrderTrackingMapView: View {
       let order: VirtualOrder
       let route: ShipmentRoute

       var body: some View {
           TimelineView(.periodic(from: .now, by: 1)) { context in
               let progress = order.shipmentProgress(at: context.date)
               let path = ShipmentGeometry.routeCoordinates(
                   from: route.origin, to: route.destination
               )
               Map(initialPosition: cameraPosition, interactionModes: []) {
                   MapPolyline(coordinates: path)
                       .stroke(.tint, style: StrokeStyle(
                           lineWidth: 3, lineCap: .round, dash: [6, 6]
                       ))
                   Annotation(route.originName, coordinate: route.origin) {
                       // small circle w/ "building.2" image, brand-styled
                   }
                   Annotation(route.destinationName, coordinate: route.destination) {
                       // "house.fill"
                   }
                   Annotation("Package", coordinate: ShipmentGeometry.coordinate(
                       from: route.origin, to: route.destination, fraction: progress
                   )) {
                       // "shippingbox.fill" in a tinted capsule, slightly larger
                   }
               }
           }
           .frame(height: 240)
           .clipShape(RoundedRectangle(cornerRadius: 12))
           .accessibilityElement(children: .ignore)
           .accessibilityLabel(/* "Package traveling from X to Y, Z percent of the way" */)
       }
   }
   ```

   Camera: compute once from the route (not per tick) — an
   `MKMapRect` union of all `path` points padded ~30%, exposed as
   `MapCameraPosition.rect(...)`. `interactionModes: []` keeps the map static
   inside the `List`; that is intentional.

   Add a `#Preview` using `PreviewData` orders, matching how other Orders
   previews are written.

2. **`OrderDetailView.swift`** — insert a new section between the summary
   section and `Section("Items")`:

   ```swift
   if let route = order.shipmentRoute {
       Section("Shipment") {
           VStack(alignment: .leading, spacing: 8) {
               OrderTrackingMapView(order: order, route: route)
               Text("Simulated route from \(route.originName) to \(route.destinationName)")
                   .font(.footnote)
                   .foregroundStyle(.secondary)
           }
           .padding(.vertical, 4)
       }
       .brandListRow()
   }
   ```

   Show the section for all non-cancelled statuses (package sits at the origin
   until `shipped`) — `shipmentRoute` already returns nil for cancelled orders
   and for legacy rows missing coordinates.

3. Do not change `OrdersView.swift` / `OrderRow.swift`; the map lives only on
   the detail screen.

### Verify Phase 3

- Build again (same command as Phase 2).
- Run the swiftui-pro review over the new/changed SwiftUI files and fix
  genuine findings.
- If a simulator is available: run the app, place an order (or use Bruno
  `Simulate Order Shipping` with `force: true` to advance stages), open the
  order detail, and confirm the marker moves origin → destination and lands on
  the destination when delivered. The existing 15-second refresh in
  `OrdersViewModel.observe(using:)` picks up status changes; no view-model
  changes are needed.

---

## Phase 4 — Tests

**Read first:** `Shopping/ShoppingTests/OrderListFilterTests.swift` (Swift
Testing style: `import Testing`, `@testable import Shopping`, `struct` +
`@Test` + `#expect`).

New file `Shopping/ShoppingTests/ShipmentTrackingTests.swift` covering:

- `ShipmentGeometry.coordinate`: fraction 0 returns start, 1 returns end,
  0.5 between Seattle and Tokyo is within ~1° of the great-circle midpoint
  (expected ≈ (56.2, 195.7 − 360 = −164.3); assert with tolerance, or simpler:
  assert midpoint latitude > both endpoint latitudes for that pair, proving
  great-circle rather than linear interpolation). Also: identical start/end
  does not divide by zero; fractions below 0 / above 1 clamp.
- `ShipmentGeometry.routeCoordinates`: returns `sampleCount` points, first ==
  start, last == end.
- `VirtualOrder.shipmentProgress(at:)`: 0 for `.ordered`/`.processing`; 1 for
  `.delivered` even if the date is early; mid-value for `.shipped` halfway
  between `shippedAt` and `estimatedDeliveryAt`; clamped to 1 past
  `estimatedDeliveryAt`; safe when `shippedAt`/`estimatedDeliveryAt` is nil.
- `VirtualOrder.shipmentRoute`: nil when any coordinate is missing; nil when
  `.cancelled`; non-nil with all fields.

Build test fixtures with the memberwise `VirtualOrder` initializer (see
`PreviewData.swift` for a template).

Run:

```sh
xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

(Adjust the simulator name to one available via
`xcrun simctl list devices available`.) All tests must pass.

---

## Phase 5 — Docs

Update `docs/SHIPPING_SIMULATION.md`: add a "Tracking Route" section
documenting the six `virtual_orders` columns, the deterministic assignment
(`private.virtual_order_route`, seeded by order id, assigned by the
before-insert trigger), and that the client interpolates the package position
between `shipped_at` and `estimated_delivery_at`. Keep the existing tone and
table style.

No Bruno changes required (`Simulate Order Shipping.yml` already returns the
whole order row), but if Bruno assertions exist on the response shape, extend
rather than replace them.

## Completion checklist

- [ ] Migration applies cleanly via `supabase db reset`; new orders get
      distinct origin/destination; old orders backfilled.
- [ ] Simulate Order Shipping response includes route fields.
- [ ] App builds with no new warnings; all unit tests pass.
- [ ] Map renders in order detail for ordered/processing/shipped/
      out_for_delivery/delivered; hidden for cancelled and legacy orders
      without coordinates.
- [ ] swiftui-pro review run on new SwiftUI files; findings addressed.
- [ ] `docs/SHIPPING_SIMULATION.md` updated.
