import Foundation
import LocalAuthentication

/// Confirms a checkout with Face ID / Touch ID, falling back to the device
/// passcode. `.deviceOwnerAuthentication` provides the passcode fallback
/// automatically, including when biometrics are unenrolled or locked out.
struct BiometricCheckoutAuthenticator: CheckoutAuthenticating {
    func confirmCheckout(
        reason: String
    ) async -> CheckoutAuthenticationResult {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel Order"

        var availabilityError: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &availabilityError
        ) else {
            return .unavailable
        }

        do {
            let confirmed = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return confirmed
                ? .confirmed
                : .failed("Authentication didn’t complete. Try again.")
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .systemCancel, .appCancel, .userFallback:
                return .cancelled
            case .passcodeNotSet:
                return .unavailable
            case .biometryLockout:
                return .failed(
                    "Biometrics are locked. Unlock your device with its passcode, then try again."
                )
            default:
                return .failed(error.localizedDescription)
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
