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

    static var orders: [VirtualOrder] {
        let now = Date.now
        let orderID = UUID(uuidString: "F1FE99E6-E99C-431A-ABA9-CCE5D2A9DE5B") ?? UUID()

        return [
            VirtualOrder(
                id: orderID,
                status: .shipped,
                totalAmount: 179.99,
                currencyCode: "USD",
                placedAt: now.addingTimeInterval(-180),
                processingAt: now.addingTimeInterval(-120),
                shippedAt: now.addingTimeInterval(-60),
                outForDeliveryAt: nil,
                deliveredAt: nil,
                cancelledAt: nil,
                estimatedDeliveryAt: now.addingTimeInterval(180),
                nextStatusAt: now.addingTimeInterval(120),
                createdAt: now.addingTimeInterval(-180),
                items: [
                    VirtualOrderItem(
                        id: UUID(),
                        productID: UUID(
                            uuidString: "231525F8-2C65-4B6F-BAF3-DDAA68958549"
                        ),
                        title: "Wooting 60HE+",
                        imageURL: URL(
                            string: "https://wooting-website.ams3.cdn.digitaloceanspaces.com/products/keyboards/60HE/60HE_OG.webp"
                        ),
                        currencyCode: "USD",
                        unitPriceAmount: 179.99,
                        quantity: 1,
                        createdAt: now.addingTimeInterval(-180)
                    ),
                ],
                events: [
                    VirtualOrderStatusEvent(
                        id: 1,
                        status: .ordered,
                        occurredAt: now.addingTimeInterval(-180)
                    ),
                    VirtualOrderStatusEvent(
                        id: 2,
                        status: .processing,
                        occurredAt: now.addingTimeInterval(-120)
                    ),
                    VirtualOrderStatusEvent(
                        id: 3,
                        status: .shipped,
                        occurredAt: now.addingTimeInterval(-60)
                    ),
                ]
            ),
        ]
    }

    static var signedOutAppModel: AppModel {
        AppModel(
            authService: PreviewAuthService(hasSession: false),
            walletService: PreviewWalletService(wallet: nil),
            onboardingService: PreviewOnboardingService(currencies: currencies),
            productImportService: PreviewProductImportService(),
            ordersService: PreviewOrdersService(orders: [])
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
            productImportService: PreviewProductImportService(),
            ordersService: PreviewOrdersService(orders: [])
        )
        model.phase = .needsCurrency
        return model
    }

    static var readyAppModel: AppModel {
        let model = AppModel(
            authService: PreviewAuthService(hasSession: true),
            walletService: PreviewWalletService(wallet: wallet),
            onboardingService: PreviewOnboardingService(currencies: currencies),
            productImportService: PreviewProductImportService(),
            ordersService: PreviewOrdersService(orders: orders)
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

private struct PreviewOrdersService: OrdersServing {
    let orders: [VirtualOrder]

    func listOrders() async throws -> [VirtualOrder] {
        orders
    }
}
