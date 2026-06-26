import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private let authService: any AuthServing
    private let walletService: any WalletServing
    private let onboardingService: any OnboardingServing

    var phase: AppPhase = .launching
    var wallet: VirtualWallet?

    init(
        authService: any AuthServing,
        walletService: any WalletServing,
        onboardingService: any OnboardingServing
    ) {
        self.authService = authService
        self.walletService = walletService
        self.onboardingService = onboardingService
    }

    static func live() -> AppModel {
        do {
            let dependencies = try LiveDependencies()
            return AppModel(
                authService: dependencies.authService,
                walletService: dependencies.walletService,
                onboardingService: dependencies.onboardingService
            )
        } catch {
            let model = AppModel(
                authService: UnavailableAuthService(),
                walletService: UnavailableWalletService(),
                onboardingService: UnavailableOnboardingService()
            )
            model.phase = .configurationError(error.localizedDescription)
            return model
        }
    }

    func start() async {
        guard case .launching = phase else { return }

        do {
            guard try await authService.hasSession() else {
                phase = .signedOut
                return
            }
            await refreshWallet()
        } catch {
            phase = .signedOut
        }
    }

    func signIn(email: String, password: String) async throws {
        try await authService.signIn(email: email, password: password)
        await refreshWallet()
    }

    func signUp(email: String, password: String) async throws {
        try await authService.signUp(email: email, password: password)
        await refreshWallet()
    }

    func signOut() async {
        try? await authService.signOut()
        wallet = nil
        phase = .signedOut
    }

    func listCurrencies() async throws -> [SupportedCurrency] {
        try await onboardingService.listCurrencies()
    }

    func selectHomeCurrency(_ currencyCode: String) async throws {
        wallet = try await onboardingService.setHomeCurrency(currencyCode)
        phase = .ready
    }

    func refreshWallet() async {
        do {
            let wallet = try await walletService.getWallet()
            self.wallet = wallet
            phase = wallet.homeCurrencySelected ? .ready : .needsCurrency
        } catch {
            phase = .signedOut
        }
    }
}
