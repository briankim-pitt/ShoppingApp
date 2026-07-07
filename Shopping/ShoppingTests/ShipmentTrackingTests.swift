import CoreLocation
import Foundation
import Testing
@testable import Shopping

struct ShipmentTrackingTests {
    @Test
    func coordinateReturnsEndpointsAtBounds() {
        let start = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let end = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        let first = ShipmentGeometry.coordinate(from: start, to: end, fraction: 0)
        let last = ShipmentGeometry.coordinate(from: start, to: end, fraction: 1)

        #expect(first.isClose(to: start))
        #expect(last.isClose(to: end))
    }

    @Test
    func coordinateUsesGreatCirclePath() {
        let seattle = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let tokyo = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        let midpoint = ShipmentGeometry.coordinate(
            from: seattle,
            to: tokyo,
            fraction: 0.5
        )

        #expect(midpoint.latitude > seattle.latitude)
        #expect(midpoint.latitude > tokyo.latitude)
    }

    @Test
    func coordinateHandlesIdenticalAndClampedFractions() {
        let start = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let end = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        let identical = ShipmentGeometry.coordinate(
            from: start,
            to: start,
            fraction: 0.5
        )
        let belowZero = ShipmentGeometry.coordinate(from: start, to: end, fraction: -1)
        let aboveOne = ShipmentGeometry.coordinate(from: start, to: end, fraction: 2)

        #expect(identical.isClose(to: start))
        #expect(belowZero.isClose(to: start))
        #expect(aboveOne.isClose(to: end))
    }

    @Test
    func routeCoordinatesIncludesRequestedSamplesAndEndpoints() {
        let start = CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321)
        let end = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        let coordinates = ShipmentGeometry.routeCoordinates(
            from: start,
            to: end,
            sampleCount: 5
        )

        #expect(coordinates.count == 5)
        #expect(coordinates.first?.isClose(to: start) == true)
        #expect(coordinates.last?.isClose(to: end) == true)
    }

    @Test
    func shipmentProgressMatchesStatusAndDates() {
        let shippedAt = Date(timeIntervalSince1970: 1_000)
        let estimatedDeliveryAt = Date(timeIntervalSince1970: 1_200)
        let halfway = Date(timeIntervalSince1970: 1_100)

        #expect(makeOrder(status: .ordered).shipmentProgress(at: halfway) == 0)
        #expect(makeOrder(status: .processing).shipmentProgress(at: halfway) == 0)
        #expect(makeOrder(status: .delivered).shipmentProgress(at: shippedAt) == 1)

        let shippedOrder = makeOrder(
            status: .shipped,
            shippedAt: shippedAt,
            estimatedDeliveryAt: estimatedDeliveryAt
        )
        #expect(shippedOrder.shipmentProgress(at: halfway) == 0.5)
        #expect(
            shippedOrder.shipmentProgress(
                at: Date(timeIntervalSince1970: 1_300)
            ) == 1
        )
        #expect(
            makeOrder(
                status: .shipped,
                shippedAt: nil,
                estimatedDeliveryAt: nil
            )
            .shipmentProgress(at: halfway) == 0
        )
    }

    @Test
    func shipmentRouteRequiresCompleteActiveRoute() {
        #expect(makeOrder(status: .cancelled).shipmentRoute == nil)
        #expect(makeOrder(originLatitude: nil).shipmentRoute == nil)

        let route = makeOrder().shipmentRoute

        #expect(route?.originName == "Seattle Fulfillment Center")
        #expect(route?.destinationName == "Tokyo Fulfillment Center")
    }

    private func makeOrder(
        status: VirtualOrderStatus = .shipped,
        shippedAt: Date? = Date(timeIntervalSince1970: 1_000),
        estimatedDeliveryAt: Date? = Date(timeIntervalSince1970: 1_200),
        originLatitude: Double? = 47.6062
    ) -> VirtualOrder {
        VirtualOrder(
            id: UUID(uuidString: "F1FE99E6-E99C-431A-ABA9-CCE5D2A9DE5B") ?? UUID(),
            status: status,
            totalAmount: 179.99,
            currencyCode: "WCN",
            placedAt: Date(timeIntervalSince1970: 900),
            processingAt: Date(timeIntervalSince1970: 950),
            shippedAt: shippedAt,
            outForDeliveryAt: nil,
            deliveredAt: status == .delivered ? Date(timeIntervalSince1970: 1_200) : nil,
            cancelledAt: status == .cancelled ? Date(timeIntervalSince1970: 1_000) : nil,
            estimatedDeliveryAt: estimatedDeliveryAt,
            nextStatusAt: nil,
            originName: "Seattle Fulfillment Center",
            originLatitude: originLatitude,
            originLongitude: -122.3321,
            destinationName: "Tokyo Fulfillment Center",
            destinationLatitude: 35.6762,
            destinationLongitude: 139.6503,
            createdAt: Date(timeIntervalSince1970: 900),
            items: [],
            events: []
        )
    }
}

private extension CLLocationCoordinate2D {
    func isClose(
        to other: CLLocationCoordinate2D,
        tolerance: Double = 0.000_001
    ) -> Bool {
        abs(latitude - other.latitude) < tolerance
            && abs(longitude - other.longitude) < tolerance
    }
}
