import MapKit
import SwiftUI

struct OrdersMapView: View {
    private let shipments: [OrderShipment]

    init(orders: [VirtualOrder]) {
        shipments = orders.compactMap(OrderShipment.init)
    }

    var body: some View {
        if !shipments.isEmpty {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Map(initialPosition: initialPosition) {
                    ForEach(shipments) { shipment in
                        MapPolyline(coordinates: shipment.path)
                            .stroke(
                                Color.brandPrimary.opacity(0.6),
                                style: StrokeStyle(
                                    lineWidth: 2,
                                    lineCap: .round,
                                    dash: [5, 5]
                                )
                            )

                        Annotation(
                            shipment.route.destinationName,
                            coordinate: shipment.route.destination
                        ) {
                            Circle()
                                .fill(Color.brandSuccess)
                                .frame(width: 8, height: 8)
                                .padding(4)
                                .background(.regularMaterial, in: Circle())
                        }
                        .annotationTitles(.hidden)

                        Annotation(
                            shipment.order.primaryItemTitle,
                            coordinate: shipment.packageCoordinate(at: context.date)
                        ) {
                            Image(systemName: "shippingbox.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(7)
                                .background(Color.brandPrimary, in: Circle())
                                .shadow(
                                    color: Color.brandPrimary.opacity(0.3),
                                    radius: 6,
                                    y: 2
                                )
                        }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel)
            }
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var initialPosition: MapCameraPosition {
        .rect(
            MKMapRect(fitting: shipments.flatMap(\.path))
                .padded(by: 0.2)
        )
    }

    private var accessibilityLabel: String {
        "Map of \(shipments.count) shipment\(shipments.count == 1 ? "" : "s") in transit"
    }
}

#Preview {
    OrdersMapView(orders: PreviewData.orders)
        .padding()
}
