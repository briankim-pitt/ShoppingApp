# Backlog

## Face ID Checkout Confirmation

**Status:** Deferred

Add an optional local authentication step immediately before submitting a
virtual checkout.

Acceptance criteria:

- Use `LocalAuthentication` with biometrics and device-passcode fallback.
- Explain that authentication confirms a simulated purchase.
- Do not create an order when authentication fails or is cancelled.
- Handle unavailable or unenrolled biometrics without blocking the user.
- Keep balance validation and order creation on the backend.
- Cover success, failure, cancellation, lockout, and unavailable-device states.

Face ID is not part of the current cart and checkout milestone.
