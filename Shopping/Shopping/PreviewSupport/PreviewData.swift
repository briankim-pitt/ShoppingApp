import Foundation

@MainActor
enum PreviewData {
    static let currencies = [
        SupportedCurrency(
            currencyCode: "USD",
            displayName: "US Dollar",
            symbol: "$",
            minorUnit: 2
        ),
        SupportedCurrency(
            currencyCode: "JPY",
            displayName: "Japanese Yen",
            symbol: "¥",
            minorUnit: 0
        ),
        SupportedCurrency(
            currencyCode: "EUR",
            displayName: "Euro",
            symbol: "€",
            minorUnit: 2
        ),
    ]

    static let wallet = VirtualWallet(
        balance: Money(amount: 850, currencyCode: "USD"),
        homeCurrencySelected: true,
        homeCurrencySelectedAt: .now
    )

    static var signedOutAppModel: AppModel {
        AppModel(
            authService: PreviewAuthService(hasSession: false),
            walletService: PreviewWalletService(wallet: nil),
            onboardingService: PreviewOnboardingService(currencies: currencies),
            productImportService: PreviewProductImportService()
        )
    }

    static var onboardingAppModel: AppModel {
        let model = AppModel(
            authService: PreviewAuthService(hasSession: true),
            walletService: PreviewWalletService(
                wallet: VirtualWallet(
                    balance: Money(amount: 1000, currencyCode: "USD"),
                    homeCurrencySelected: false,
                    homeCurrencySelectedAt: nil
                )
            ),
            onboardingService: PreviewOnboardingService(currencies: currencies),
            productImportService: PreviewProductImportService()
        )
        model.phase = .needsCurrency
        return model
    }

    static var readyAppModel: AppModel {
        let model = AppModel(
            authService: PreviewAuthService(hasSession: true),
            walletService: PreviewWalletService(wallet: wallet),
            onboardingService: PreviewOnboardingService(currencies: currencies),
            productImportService: PreviewProductImportService()
        )
        model.wallet = wallet
        model.phase = .ready
        return model
    }
}

private struct PreviewAuthService: AuthServing {
    let hasSessionValue: Bool

    init(hasSession: Bool) {
        hasSessionValue = hasSession
    }

    func hasSession() async throws -> Bool { hasSessionValue }
    func signIn(email: String, password: String) async throws {}
    func signUp(email: String, password: String) async throws {}
    func signOut() async throws {}
}

private struct PreviewWalletService: WalletServing {
    let wallet: VirtualWallet?

    func getWallet() async throws -> VirtualWallet {
        guard let wallet else {
            throw APIError.invalidResponse
        }
        return wallet
    }
}

private struct PreviewOnboardingService: OnboardingServing {
    let currencies: [SupportedCurrency]

    func listCurrencies() async throws -> [SupportedCurrency] {
        currencies
    }

    func setHomeCurrency(_ currencyCode: String) async throws -> VirtualWallet {
        VirtualWallet(
            balance: Money(amount: 1000, currencyCode: currencyCode),
            homeCurrencySelected: true,
            homeCurrencySelectedAt: .now
        )
    }
}

private struct PreviewProductImportService: ProductImportServing {
    func importProduct(from url: URL) async throws -> ProductImportResult {
        let product = Product(
            id: UUID(uuidString: "231525F8-2C65-4B6F-BAF3-DDAA68958549") ?? UUID(),
            canonicalURL: url,
            sourceDomain: url.host() ?? "example.com",
            title: "Wooting 60HE+",
            description: "Analog mechanical keyboard with rapid trigger and a compact layout.",
            imageURL: URL(string: "https://wooting-website.ams3.cdn.digitaloceanspaces.com/products/keyboards/60HE/60HE_OG.webp"),
            currencyCode: "USD",
            priceAmount: 174.99,
            createdAt: .now,
            updatedAt: .now,
            lastImportedAt: .now
        )

        return ProductImportResult(
            product: product,
            importRecord: ProductImport(
                id: UUID(),
                userID: UUID(),
                sourceURL: url,
                canonicalURL: url,
                sourceDomain: product.sourceDomain,
                productID: product.id,
                status: "succeeded",
                errorMessage: nil,
                createdAt: .now
            )
        )
    }
}
