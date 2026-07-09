import Foundation
import Observation

@MainActor
@Observable
final class CartViewModel {
    var isCheckingOut = false
    var errorMessage: String?
    var isShowingCheckoutConfirmation = false
    var isShowingClearConfirmation = false

    /// Signals a Face ID outcome for the view to play haptic feedback. Each
    /// value carries a fresh id so repeated same-type outcomes retrigger.
    enum AuthenticationHaptic: Equatable {
        case success(UUID)
        case failure(UUID)
    }

    private(set) var authenticationHaptic: AuthenticationHaptic?

    @ObservationIgnored private var idempotencyKey: UUID?
    @ObservationIgnored private var checkoutRevision: UUID?

    private let authenticator: any CheckoutAuthenticating

    init(
        authenticator: any CheckoutAuthenticating = BiometricCheckoutAuthenticator()
    ) {
        self.authenticator = authenticator
    }

    func requestCheckout() {
        errorMessage = nil
        isShowingCheckoutConfirmation = true
    }

    func checkout(using appModel: AppModel) async {
        guard !isCheckingOut else { return }

        isCheckingOut = true
        errorMessage = nil
        defer { isCheckingOut = false }

        // Authenticate before creating any order; the backend still owns
        // balance validation and order creation.
        switch await authenticator.confirmCheckout(
            reason: authenticationReason(for: appModel.cart.total())
        ) {
        case .confirmed:
            authenticationHaptic = .success(UUID())
        case .unavailable:
            // No biometric prompt ran, so there is no auth outcome to signal.
            break
        case .cancelled:
            return
        case .failed(let message):
            authenticationHaptic = .failure(UUID())
            errorMessage = message
            return
        }

        let cart = appModel.cart
        let revision = cart.revision
        let key: UUID

        if checkoutRevision == revision, let idempotencyKey {
            key = idempotencyKey
        } else {
            key = UUID()
            idempotencyKey = key
            checkoutRevision = revision
        }

        do {
            _ = try await appModel.checkoutCart(idempotencyKey: key)
            idempotencyKey = nil
            checkoutRevision = nil
            appModel.cart.clear()
            appModel.selectedTab = .orders
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func authenticationReason(for total: Decimal?) -> String {
        guard let total else {
            return "Confirm your simulated order. No real payment is made."
        }

        return "Confirm your simulated order of \(total.wanderCoinText). No real payment is made."
    }
}
