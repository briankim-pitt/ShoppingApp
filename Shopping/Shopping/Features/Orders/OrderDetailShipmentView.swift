import SwiftUI

struct OrderDetailShipmentView: View {
    let order: VirtualOrder
    let route: ShipmentRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shipment")
                .font(.headline)

            OrderTrackingMapView(order: order, route: route)
                .orderItemCardStyle()

            Text("\(route.originName) to \(route.destinationName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 2)
        }
    }
}
