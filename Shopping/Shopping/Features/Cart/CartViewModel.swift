import Foundation
import Observation

@MainActor
@Observable
final class CartViewModel {
    var isCheckingOut = false
    var errorMessage: String?
    var isShowingCheckoutConfirmation = false
    var isShowingClearConfirmation = false

    @ObservationIgnored private var idempotencyKey: UUID?
    @ObservationIgnored private var checkoutRevision: UUID?

    func requestCheckout() {
        errorMessage = nil
        isShowingCheckoutConfirmation = true
    }

    func checkout(using appModel: AppModel) async {
        guard !isCheckingOut else { return }

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

        isCheckingOut = true
        errorMessage = nil
        defer { isCheckingOut = false }

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
}
