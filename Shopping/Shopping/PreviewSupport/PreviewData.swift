import Foundation

@MainActor
enum PreviewData {
    static let wallet = VirtualWallet(
        balance: Money(amount: 1250, currencyCode: "WCN"),
        homeCurrencySelected: true,
        homeCurrencySelectedAt: .now
    )

    static let dailyCheckInStatus = DailyCheckInStatus(
        claimedToday: false,
        rewardAmount: 100,
        streakCount: 4,
        claimedAt: nil,
        balance: wallet.balance
    )

    nonisolated static var product: Product {
        Product(
            id: UUID(uuidString: "231525F8-2C65-4B6F-BAF3-DDAA68958549") ?? UUID(),
            canonicalURL: URL(string: "https://wooting.io/wooting-60he")
                ?? URL(fileURLWithPath: "/"),
            sourceDomain: "wooting.io",
            title: "Wooting 60HE+",
            description: "Analog mechanical keyboard with rapid trigger and a compact layout.",
            brand: "Wooting",
            imageURL: URL(string: "https://wooting-website.ams3.cdn.digitaloceanspaces.com/products/keyboards/60HE/60HE_OG.webp"),
            currencyCode: "USD",
            priceAmount: 174.99,
            wanderCoinPriceAmount: 175,
            createdAt: .now,
            updatedAt: .now,
            lastImportedAt: .now
        )
    }

    nonisolated static var products: [Product] {
        [
            product,
            Product(
                id: UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000001") ?? UUID(),
                canonicalURL: URL(string: "https://www.keychron.com/products/keychron-q1")
                    ?? URL(fileURLWithPath: "/"),
                sourceDomain: "keychron.com",
                title: "Keychron Q1 Pro",
                description: "Wireless custom mechanical keyboard with a gasket-mounted design.",
                brand: "Keychron",
                imageURL: URL(string: "https://www.keychron.com/cdn/shop/products/Keychron-Q1-Pro-QMK-VIA-wireless-custom-mechanical-keyboard.jpg"),
                currencyCode: "USD",
                priceAmount: 199.00,
                wanderCoinPriceAmount: 199,
                createdAt: .now,
                updatedAt: .now,
                lastImportedAt: .now
            ),
            Product(
                id: UUID(uuidString: "A1B2C3D4-0000-0000-0000-000000000002") ?? UUID(),
                canonicalURL: URL(string: "https://www.logitech.com/products/mice/mx-master-3s")
                    ?? URL(fileURLWithPath: "/"),
                sourceDomain: "logitech.com",
                title: "Logitech MX Master 3S",
                description: "Ergonomic wireless mouse with quiet clicks and fast scrolling.",
                brand: "Logitech",
                imageURL: URL(string: "https://resource.logitech.com/w_800,c_lpad,q_auto,f_auto,dpr_1.0/d_transparent.gif/content/dam/logitech/en/products/mice/mx-master-3s/gallery/mx-master-3s-mouse-top-view-graphite.png"),
                currencyCode: "USD",
                priceAmount: 99.99,
                wanderCoinPriceAmount: 100,
                createdAt: .now,
                updatedAt: .now,
                lastImportedAt: .now
            ),
        ]
    }

    @MainActor
    static var recentlyViewedStore: RecentlyViewedStore {
        // A throwaway suite keeps preview seeding out of the real defaults.
        let suiteName = "preview.recentlyViewed"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)

        let store = RecentlyViewedStore(defaults: defaults)
        for product in products.reversed() {
            store.record(product)
        }
        return store
    }

    static var orders: [VirtualOrder] {
        let now = Date.now
        let orderID = UUID(uuidString: "F1FE99E6-E99C-431A-ABA9-CCE5D2A9DE5B") ?? UUID()

        return [
            VirtualOrder(
                id: orderID,
                status: .shipped,
                totalAmount: 179.99,
                currencyCode: "WCN",
                placedAt: now.addingTimeInterval(-180),
                processingAt: now.addingTimeInterval(-120),
                shippedAt: now.addingTimeInterval(-60),
                outForDeliveryAt: nil,
                deliveredAt: nil,
                cancelledAt: nil,
                estimatedDeliveryAt: now.addingTimeInterval(180),
                nextStatusAt: now.addingTimeInterval(120),
                originName: "Seattle Fulfillment Center",
                originLatitude: 47.6062,
                originLongitude: -122.3321,
                destinationName: "Tokyo Fulfillment Center",
                destinationLatitude: 35.6762,
                destinationLongitude: 139.6503,
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
                        currencyCode: "WCN",
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
            productImportService: PreviewProductImportService(),
            catalogService: PreviewCatalogService(),
            ordersService: PreviewOrdersService(orders: []),
            checkoutService: PreviewCheckoutService(),
            wishlistService: PreviewWishlistService()
        )
    }

    static var readyAppModel: AppModel {
        let model = AppModel(
            authService: PreviewAuthService(hasSession: true),
            walletService: PreviewWalletService(wallet: wallet),
            productImportService: PreviewProductImportService(),
            catalogService: PreviewCatalogService(),
            ordersService: PreviewOrdersService(orders: orders),
            checkoutService: PreviewCheckoutService(),
            wishlistService: PreviewWishlistService(),
            recentlyViewed: recentlyViewedStore
        )
        model.wallet = wallet
        model.dailyCheckInStatus = dailyCheckInStatus
        model.phase = .ready
        return model
    }

    static var cartAppModel: AppModel {
        let model = readyAppModel
        model.cart.add(product)
        return model
    }
}

private struct PreviewAuthService: AuthServing {
    let hasSessionValue: Bool

    init(hasSession: Bool) {
        hasSessionValue = hasSession
    }

    func hasSession() async throws -> Bool { hasSessionValue }
    func currentEmail() async -> String? {
        hasSessionValue ? "shopper@wandercart.app" : nil
    }
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

    func getDailyCheckInStatus() async throws -> DailyCheckInStatus {
        guard let wallet else {
            throw APIError.invalidResponse
        }

        return DailyCheckInStatus(
            claimedToday: false,
            rewardAmount: 100,
            streakCount: 4,
            claimedAt: nil,
            balance: wallet.balance
        )
    }

    func claimDailyCheckIn() async throws -> DailyCheckInStatus {
        guard let wallet else {
            throw APIError.invalidResponse
        }

        return DailyCheckInStatus(
            claimedToday: true,
            rewardAmount: 100,
            streakCount: 5,
            claimedAt: .now,
            balance: Money(
                amount: wallet.balance.amount + 100,
                currencyCode: "WCN"
            )
        )
    }
}

private struct PreviewProductImportService: ProductImportServing {
    func importProduct(
        from url: URL,
        extracted: ExtractedProductMetadata?
    ) async throws -> ProductImportResult {
        let product = PreviewData.product

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

    func deleteImport(forProductID productID: UUID) async throws {
    }
}

private struct PreviewCatalogService: CatalogServing {
    func browseProducts() async throws -> [Product] {
        [PreviewData.product]
    }

    func searchProducts(query: String) async throws -> [Product] {
        [PreviewData.product]
    }

    func products(forBrand brand: String) async throws -> [Product] {
        [PreviewData.product]
    }

    func listBrands() async throws -> [ProductBrand] {
        [
            ProductBrand(name: "Wooting", matchCount: 12),
            ProductBrand(name: "Keychron", matchCount: 8),
        ]
    }

    func heroImage(forProductID productID: UUID) async throws -> URL? {
        PreviewData.product.imageURL
    }
}

private struct PreviewOrdersService: OrdersServing {
    let orders: [VirtualOrder]

    func listOrders() async throws -> [VirtualOrder] {
        orders
    }
}

private struct PreviewCheckoutService: CheckoutServing {
    func checkout(
        items: [CartItem],
        idempotencyKey: UUID
    ) async throws -> CartCheckoutResult {
        let total = items.reduce(Decimal.zero) {
            $0 + ($1.lineTotal ?? 0)
        }
        return CartCheckoutResult(
            order: PlacedVirtualOrder(
                id: UUID(),
                status: .ordered,
                totalAmount: total,
                currencyCode: "WCN",
                estimatedDeliveryAt: Date.now.addingTimeInterval(270)
            ),
            items: items.map {
                VirtualOrderItem(
                    id: UUID(),
                    productID: $0.product.id,
                    title: $0.product.title,
                    imageURL: $0.product.imageURL,
                    currencyCode: "WCN",
                    unitPriceAmount: $0.unitCoinPrice ?? 0,
                    quantity: $0.quantity,
                    createdAt: .now
                )
            },
            balance: Money(
                amount: max(Decimal(1250) - total, 0),
                currencyCode: "WCN"
            ),
            idempotentReplay: false
        )
    }
}

private struct PreviewWishlistService: WishlistServing {
    func contains(productID: UUID) async throws -> Bool {
        false
    }

    func add(productID: UUID) async throws {}
}
