import Foundation
import Testing
@testable import Shopping

@MainActor
struct ProductRecommendationEngineTests {
    @Test
    func ranksSimilarProductsAheadOfUnrelatedProducts() {
        let viewedKeyboard = product(
            id: "00000000-0000-0000-0000-000000000001",
            title: "Wooting 60HE Keyboard",
            brand: "Wooting",
            description: "Analog mechanical gaming keyboard",
            price: 175
        )
        let similarKeyboard = product(
            id: "00000000-0000-0000-0000-000000000002",
            title: "Wooting Two HE Keyboard",
            brand: "Wooting",
            description: "Full-size analog mechanical keyboard",
            price: 190
        )
        let unrelatedShoes = product(
            id: "00000000-0000-0000-0000-000000000003",
            title: "Running Shoes",
            brand: "Stride",
            description: "Lightweight road running shoes",
            price: 120
        )

        let result = ProductRecommendationEngine.recommendations(
            from: [unrelatedShoes, similarKeyboard, viewedKeyboard],
            recentlyViewed: [viewedKeyboard],
            orders: []
        )

        #expect(result.first?.id == similarKeyboard.id)
    }

    @Test
    func excludesViewedAndOrderedProducts() {
        let viewed = product(
            id: "00000000-0000-0000-0000-000000000011",
            title: "Viewed Keyboard",
            brand: "Keys",
            description: "Mechanical keyboard",
            price: 100
        )
        let ordered = product(
            id: "00000000-0000-0000-0000-000000000012",
            title: "Ordered Keyboard",
            brand: "Keys",
            description: "Mechanical keyboard",
            price: 110
        )
        let candidate = product(
            id: "00000000-0000-0000-0000-000000000013",
            title: "Recommended Keyboard",
            brand: "Keys",
            description: "Mechanical keyboard",
            price: 105
        )
        let order = PreviewData.orders[0]
        let orderedItem = VirtualOrderItem(
            id: UUID(),
            productID: ordered.id,
            title: ordered.title,
            imageURL: nil,
            currencyCode: "WCN",
            unitPriceAmount: 110,
            quantity: 1,
            createdAt: .now
        )
        let orderWithProduct = VirtualOrder(
            id: order.id,
            status: order.status,
            totalAmount: order.totalAmount,
            currencyCode: order.currencyCode,
            placedAt: order.placedAt,
            processingAt: order.processingAt,
            shippedAt: order.shippedAt,
            outForDeliveryAt: order.outForDeliveryAt,
            deliveredAt: order.deliveredAt,
            cancelledAt: order.cancelledAt,
            estimatedDeliveryAt: order.estimatedDeliveryAt,
            nextStatusAt: order.nextStatusAt,
            originName: order.originName,
            originLatitude: order.originLatitude,
            originLongitude: order.originLongitude,
            destinationName: order.destinationName,
            destinationLatitude: order.destinationLatitude,
            destinationLongitude: order.destinationLongitude,
            createdAt: order.createdAt,
            items: [orderedItem],
            events: order.events
        )

        let result = ProductRecommendationEngine.recommendations(
            from: [viewed, ordered, candidate],
            recentlyViewed: [viewed],
            orders: [orderWithProduct]
        )

        #expect(result.map(\.id) == [candidate.id])
    }

    private func product(
        id: String,
        title: String,
        brand: String,
        description: String,
        price: Decimal
    ) -> Product {
        Product(
            id: UUID(uuidString: id) ?? UUID(),
            canonicalURL: URL(string: "https://example.com/\(id)")!,
            sourceDomain: "example.com",
            title: title,
            description: description,
            brand: brand,
            imageURL: nil,
            currencyCode: "USD",
            priceAmount: price,
            wanderCoinPriceAmount: price,
            createdAt: .now,
            updatedAt: .now,
            lastImportedAt: .now
        )
    }
}
