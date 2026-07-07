import CoreLocation
import Foundation

struct ShipmentRoute: Equatable, Sendable {
    let originName: String
    let originLatitude: Double
    let originLongitude: Double
    let destinationName: String
    let destinationLatitude: Double
    let destinationLongitude: Double

    var origin: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: originLatitude,
            longitude: originLongitude
        )
    }

    var destination: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: destinationLatitude,
            longitude: destinationLongitude
        )
    }
}

extension VirtualOrder {
    var shipmentRoute: ShipmentRoute? {
        guard status != .cancelled,
              let originName,
              let originLatitude,
              let originLongitude,
              let destinationName,
              let destinationLatitude,
              let destinationLongitude
        else {
            return nil
        }

        return ShipmentRoute(
            originName: originName,
            originLatitude: originLatitude,
            originLongitude: originLongitude,
            destinationName: destinationName,
            destinationLatitude: destinationLatitude,
            destinationLongitude: destinationLongitude
        )
    }

    func shipmentProgress(at date: Date) -> Double {
        switch status {
        case .ordered, .processing, .cancelled:
            0
        case .delivered:
            1
        case .shipped, .outForDelivery:
            shipmentProgressBetweenShippingDates(at: date)
        }
    }

    private func shipmentProgressBetweenShippingDates(at date: Date) -> Double {
        guard let shippedAt,
              let estimatedDeliveryAt,
              estimatedDeliveryAt > shippedAt
        else {
            return 0
        }

        let elapsed = date.timeIntervalSince(shippedAt)
        let duration = estimatedDeliveryAt.timeIntervalSince(shippedAt)
        return min(max(elapsed / duration, 0), 1)
    }
}
