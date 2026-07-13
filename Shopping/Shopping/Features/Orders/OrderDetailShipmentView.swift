import SwiftUI

struct OrderDetailShipmentView: View {
    let order: VirtualOrder
    let route: ShipmentRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shipment")
                .font(.title2.bold())

            OrderTrackingMapView(order: order, route: route)

            Text("\(route.originName) to \(route.destinationName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
