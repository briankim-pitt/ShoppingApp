# Swift Project Structure

This structure is designed for a SwiftUI app backed by Supabase. It is
feature-oriented: files that change together stay together, while shared
infrastructure remains small and explicit.

`ShoppingApp` is a temporary internal name. The Xcode project, target, and
display name can be renamed later.

## Suggested Xcode Layout

```text
ShoppingApp/
├── App/
│   ├── ShoppingApp.swift
│   ├── AppContainer.swift
│   ├── AppRouter.swift
│   ├── AppRoute.swift
│   └── RootView.swift
│
├── Core/
│   ├── Config/
│   │   ├── AppEnvironment.swift
│   │   └── SupabaseConfiguration.swift
│   ├── Networking/
│   │   ├── APIError.swift
│   │   ├── EdgeFunctionClient.swift
│   │   └── NetworkMonitor.swift
│   ├── Authentication/
│   │   ├── AuthSession.swift
│   │   ├── AuthService.swift
│   │   └── BiometricAuthenticator.swift
│   ├── Persistence/
│   │   ├── SecureStore.swift
│   │   └── AppPreferences.swift
│   ├── Models/
│   │   ├── Profile.swift
│   │   ├── Product.swift
│   │   ├── Money.swift
│   │   ├── Currency.swift
│   │   ├── VirtualWallet.swift
│   │   └── VirtualOrder.swift
│   ├── DesignSystem/
│   │   ├── AppColor.swift
│   │   ├── AppTypography.swift
│   │   ├── AppSpacing.swift
│   │   └── Components/
│   └── Utilities/
│       ├── CurrencyFormatter.swift
│       └── URLNormalizer.swift
│
├── Features/
│   ├── Authentication/
│   │   ├── SignInView.swift
│   │   ├── SignInViewModel.swift
│   │   └── AuthenticationService.swift
│   │
│   ├── Onboarding/
│   │   ├── OnboardingFlowView.swift
│   │   ├── CurrencySelectionView.swift
│   │   ├── CurrencySelectionViewModel.swift
│   │   └── OnboardingService.swift
│   │
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   │
│   ├── ProductImport/
│   │   ├── ProductImportView.swift
│   │   ├── ProductReviewView.swift
│   │   ├── ProductImportViewModel.swift
│   │   ├── ProductImportService.swift
│   │   └── Models/
│   │       └── ProductDraft.swift
│   │
│   ├── ScreenshotImport/
│   │   ├── ScreenshotPickerView.swift
│   │   ├── ScreenshotCropView.swift
│   │   ├── ScreenshotReviewView.swift
│   │   ├── ScreenshotImportViewModel.swift
│   │   ├── TextRecognitionService.swift
│   │   └── Models/
│   │       └── ScreenshotProductCandidate.swift
│   │
│   ├── Checkout/
│   │   ├── CheckoutView.swift
│   │   ├── CheckoutViewModel.swift
│   │   ├── CheckoutService.swift
│   │   ├── PurchaseConfirmationView.swift
│   │   └── Models/
│   │       └── CheckoutRequest.swift
│   │
│   ├── Orders/
│   │   ├── OrderListView.swift
│   │   ├── OrderDetailView.swift
│   │   ├── DeliveryTrackingView.swift
│   │   ├── OrdersViewModel.swift
│   │   └── OrdersService.swift
│   │
│   ├── Wishlists/
│   │   ├── WishlistListView.swift
│   │   ├── WishlistDetailView.swift
│   │   ├── WishlistEditorView.swift
│   │   ├── WishlistsViewModel.swift
│   │   └── WishlistsService.swift
│   │
│   ├── Social/
│   │   ├── FriendListView.swift
│   │   ├── FriendRequestsView.swift
│   │   ├── PublicProfileView.swift
│   │   ├── SocialViewModel.swift
│   │   └── SocialService.swift
│   │
│   └── Profile/
│       ├── ProfileView.swift
│       ├── EditProfileView.swift
│       ├── WalletView.swift
│       ├── ProfileViewModel.swift
│       └── ProfileService.swift
│
├── Extensions/
│   └── ShareExtension/
│       ├── ShareViewController.swift
│       ├── SharePayload.swift
│       └── ShareExtensionService.swift
│
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   ├── Preview Content/
│   └── Configuration/
│       ├── Debug.xcconfig
│       ├── Release.xcconfig
│       └── Secrets.xcconfig.example
│
├── PreviewSupport/
│   ├── PreviewContainer.swift
│   ├── PreviewData.swift
│   └── MockServices/
│
├── ShoppingAppTests/
│   ├── Features/
│   ├── Services/
│   └── Models/
│
└── ShoppingAppUITests/
    ├── OnboardingUITests.swift
    ├── ProductImportUITests.swift
    └── CheckoutUITests.swift
```

## App Layer

The `App` directory owns application startup and navigation.

### `ShoppingApp.swift`

Creates the shared `AppContainer` and displays `RootView`.

### `AppContainer`

Builds and owns long-lived dependencies:

```swift
@MainActor
@Observable
final class AppContainer {
    let authService: AuthService
    let onboardingService: OnboardingService
    let productImportService: ProductImportService
    let checkoutService: CheckoutService
    let ordersService: OrdersService

    var session: AuthSession?
    var wallet: VirtualWallet?
}
```

Views should not create Supabase clients directly. They receive services or
view models from the container.

### `RootView`

Chooses the current application flow:

```text
No session
    → Sign in

Session, no home currency
    → Onboarding

Session and completed onboarding
    → Main app
```

## Core Layer

`Core` contains code that is shared by multiple features.

Keep it intentionally small. A type should move into `Core` only after at
least two features need it.

### Configuration

Store the Supabase URL and publishable key in build configuration:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Never include a Supabase secret or service-role key in the app.

Use separate `.xcconfig` files for local, staging, and production builds.
Do not commit the real `Secrets.xcconfig`.

### Models

Shared models represent stable concepts used throughout the app:

```swift
struct Money: Codable, Equatable, Sendable {
    let amount: Decimal
    let currencyCode: String
}

struct VirtualWallet: Codable, Equatable, Sendable {
    let balance: Money
    let homeCurrencySelected: Bool
    let homeCurrencySelectedAt: Date?
}
```

Use `Decimal`, not `Double`, for prices and balances.

### Networking

`EdgeFunctionClient` handles concerns common to all functions:

- Access token headers
- JSON encoding and decoding
- HTTP status mapping
- Authentication expiration
- Request identifiers

Individual feature services still define their own request and response types.

## Feature Structure

Each feature normally contains:

```text
Feature/
├── FeatureView.swift
├── FeatureViewModel.swift
├── FeatureService.swift
└── Models/
```

The responsibilities are:

- **View:** rendering and user interaction
- **View model:** screen state and user actions
- **Service:** Supabase queries and Edge Function calls
- **Models:** request, response, and feature-specific domain types

Avoid putting networking directly inside SwiftUI views.

## Backend Mapping

The current backend maps into Swift services as follows:

| Swift service | Backend operation |
| --- | --- |
| `AuthService` | Supabase Auth sign-in, sign-up, sign-out, session observation |
| `OnboardingService.listCurrencies()` | `GET /rest/v1/supported_currencies` |
| `OnboardingService.setHomeCurrency()` | `set-home-currency` Edge Function |
| `ProfileService.getWallet()` | `get_my_wallet` database RPC |
| `ProductImportService.importURL()` | `import-product` Edge Function |
| `CheckoutService.placeOrder()` | `place-virtual-order` Edge Function |
| `OrdersService.listOrders()` | `virtual_orders` and `virtual_order_items` |
| `WishlistsService` | `wishlists` and `wishlist_items` |
| `SocialService` | `profiles`, `friend_requests`, and `friendships` |

## First Vertical Slice

Build onboarding before the rest of the interface.

```text
ShoppingApp
    → restore Supabase session
    → call get_my_wallet
    → show sign-in when unauthenticated
    → show currency selection when currency is unset
    → show HomeView when onboarding is complete
```

The first implementation should need only:

```text
App/
Core/Config/
Core/Authentication/
Core/Models/Currency.swift
Core/Models/Money.swift
Core/Models/VirtualWallet.swift
Features/Authentication/
Features/Onboarding/
Features/Home/
PreviewSupport/
```

Create the remaining feature folders when their implementation starts. The
full tree is a destination, not a requirement to generate dozens of empty
files on day one.

## State Management

Use the Observation framework for new code:

```swift
@MainActor
@Observable
final class CurrencySelectionViewModel {
    private let service: OnboardingService

    var currencies: [Currency] = []
    var selectedCode: String?
    var isLoading = false
    var errorMessage: String?
}
```

Guidelines:

- Keep screen state on the main actor.
- Keep networking in asynchronous services.
- Pass immutable models between layers.
- Avoid a global singleton for every service.
- Keep navigation state in `AppRouter`.

## Authentication

`AuthService` should:

- Restore the existing session at launch.
- Observe authentication state changes.
- Expose the current access token through Supabase.
- Sign out when refresh fails.
- Never manually persist raw access tokens in `UserDefaults`.

Let the Supabase Swift client manage its session. Use Keychain only for secrets
that the app itself owns.

## Checkout And Face ID

Face ID confirms intent locally:

```text
CheckoutView
    → validate displayed product and price
    → BiometricAuthenticator.confirm()
    → CheckoutService.placeOrder()
    → show successful virtual order
```

Generate one idempotency UUID when checkout begins. Reuse that UUID if the
network request is retried. Generate a new UUID only for a genuinely new order.

Face ID does not change the balance. PostgreSQL remains responsible for
checking and deducting the virtual balance.

## Screenshot Import

Keep screenshot processing separate from URL importing.

Suggested pipeline:

```text
PhotosPicker
    → crop product region
    → Vision text recognition
    → build ScreenshotProductCandidate
    → user reviews title, price, currency, and image
    → upload cropped image if needed
    → save confirmed product
```

Run OCR on-device first. Do not upload the full screenshot unless cloud
analysis is required and the user has confirmed the crop.

## Share Extension

The share extension should collect only the smallest payload:

```swift
struct SharePayload: Codable {
    let url: URL?
    let title: String?
    let selectedText: String?
}
```

Place the payload in an App Group container, then open the main app to perform
authentication, importing, and confirmation. Avoid putting the full Supabase
workflow inside the extension because extensions have tighter memory and
execution limits.

## Previews

Every user-facing screen should have a preview using mock services.

```swift
#Preview("Currency Selection") {
    CurrencySelectionView(
        viewModel: .preview(
            currencies: PreviewData.currencies
        )
    )
}
```

Previews must not:

- Require a live Supabase connection
- Depend on a stored user session
- Modify local or remote data

Use `PreviewContainer` to assemble realistic screen states.

## Testing

### Unit Tests

Prioritize:

- Currency and money decoding
- View-model loading, success, and error states
- Checkout idempotency-key reuse
- API error mapping
- Screenshot price parsing

### Integration Tests

Run against local Supabase:

- Sign in
- Select home currency
- Import a product
- Place a virtual order
- Confirm the wallet balance changed

Keep integration credentials and local URLs out of the production target.

### UI Tests

Cover the highest-value journeys:

- New user completes onboarding
- Failed currency selection displays an error
- User imports and reviews a product
- Face ID success leads to checkout
- Insufficient balance is explained without creating an order

## Naming Conventions

- Views end in `View`.
- Screen state owners end in `ViewModel`.
- Backend adapters end in `Service`.
- Network payloads end in `Request` or `Response`.
- Database representations use backend field meanings, not UI wording.
- Protocols describe behavior, such as `CheckoutServing`.

## Dependency Direction

```text
Views
  ↓
View Models
  ↓
Feature Services
  ↓
Core networking and Supabase client
```

Dependencies should not point upward. `Core` must not import a feature, and one
feature should not reach into another feature's view model.

## Initial Build Order

1. Create the Xcode project and add the Supabase Swift package.
2. Add environment configuration and build the shared Supabase client.
3. Implement session restoration and sign-in.
4. Implement `get_my_wallet`.
5. Implement currency listing and selection.
6. Build `RootView` routing between authentication, onboarding, and home.
7. Add previews and unit tests for the onboarding flow.
8. Continue with URL product importing as the second vertical slice.
