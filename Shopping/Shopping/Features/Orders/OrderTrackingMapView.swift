import MapKit
import SwiftUI

struct OrderTrackingMapView: View {
    let order: VirtualOrder
    let route: ShipmentRoute

    private let routeCoordinates: [CLLocationCoordinate2D]

    init(order: VirtualOrder, route: ShipmentRoute) {
        self.order = order
        self.route = route
        routeCoordinates = ShipmentGeometry.routeCoordinates(
            from: route.origin,
            to: route.destination
        )
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let progress = order.shipmentProgress(at: context.date)
            let packageCoordinate = ShipmentGeometry.coordinate(
                from: route.origin,
                to: route.destination,
                fraction: progress
            )

            Map(initialPosition: cameraPosition) {
                MapPolyline(coordinates: routeCoordinates)
                    .stroke(
                        Color.brandPrimary,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [6, 6]
                        )
                    )

                Annotation(route.originName, coordinate: route.origin) {
                    Image(systemName: "building.2.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandPrimary)
                        .padding(8)
                        .background(.regularMaterial, in: Circle())
                }

                Annotation(route.destinationName, coordinate: route.destination) {
                    Image(systemName: "house.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandSuccess)
                        .padding(8)
                        .background(.regularMaterial, in: Circle())
                }

                Annotation("Package", coordinate: packageCoordinate) {
                    Image(systemName: "shippingbox.fill")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.brandPrimary, in: Capsule())
                        .shadow(
                            color: Color.brandPrimary.opacity(0.3),
                            radius: 8,
                            y: 3
                        )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(progress: progress))
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var cameraPosition: MapCameraPosition {
        .rect(MKMapRect(fitting: routeCoordinates).padded(by: 0.3))
    }

    private func accessibilityLabel(progress: Double) -> String {
        let percent = progress.formatted(
            .percent.precision(.fractionLength(0))
        )

        return "Package traveling from \(route.originName) to \(route.destinationName), \(percent) of the way"
    }
}

#Preview {
    if let order = PreviewData.orders.first,
       let route = order.shipmentRoute {
        OrderTrackingMapView(order: order, route: route)
            .padding()
    }
}
