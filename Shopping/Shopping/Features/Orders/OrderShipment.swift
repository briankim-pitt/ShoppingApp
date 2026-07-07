import CoreLocation
import Foundation

struct OrderShipment: Identifiable {
    let order: VirtualOrder
    let route: ShipmentRoute
    let path: [CLLocationCoordinate2D]

    var id: UUID {
        order.id
    }

    init?(order: VirtualOrder) {
        guard let route = order.shipmentRoute else {
            return nil
        }

        self.order = order
        self.route = route
        path = ShipmentGeometry.routeCoordinates(
            from: route.origin,
            to: route.destination
        )
    }

    func packageCoordinate(at date: Date) -> CLLocationCoordinate2D {
        ShipmentGeometry.coordinate(
            from: route.origin,
            to: route.destination,
            fraction: order.shipmentProgress(at: date)
        )
    }
}
