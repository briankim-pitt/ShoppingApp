enum CheckoutAuthenticationResult: Equatable, Sendable {
    /// The user confirmed the purchase.
    case confirmed
    /// The user backed out — abort the checkout silently.
    case cancelled
    /// Authentication ran and did not succeed.
    case failed(String)
    /// The device has no biometrics or passcode to ask for; checkout
    /// proceeds rather than blocking the simulated purchase.
    case unavailable
}

protocol CheckoutAuthenticating: Sendable {
    func confirmCheckout(reason: String) async -> CheckoutAuthenticationResult
}
