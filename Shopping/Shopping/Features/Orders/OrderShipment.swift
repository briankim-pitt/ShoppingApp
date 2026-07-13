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

    static func mapShipments(from orders: [VirtualOrder]) -> [OrderShipment] {
        let activeOrders = orders.filter {
            switch $0.status {
            case .processing, .shipped, .outForDelivery:
                true
            case .ordered, .delivered, .cancelled:
                false
            }
        }
        let mostRecentDelivery = orders
            .filter { $0.status == .delivered }
            .max {
                ($0.deliveredAt ?? $0.createdAt)
                    < ($1.deliveredAt ?? $1.createdAt)
            }

        return (activeOrders + [mostRecentDelivery].compactMap { $0 })
            .compactMap(Self.init)
    }

    func routeSegments(at date: Date) -> ShipmentRouteSegments {
        ShipmentGeometry.routeSegments(
            from: route.origin,
            to: route.destination,
            fraction: order.shipmentProgress(at: date)
        )
    }
}
