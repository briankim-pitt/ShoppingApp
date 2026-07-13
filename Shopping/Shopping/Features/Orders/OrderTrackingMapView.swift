import MapKit
import SwiftUI

struct OrderTrackingMapView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        TimelineView(.periodic(from: .now, by: timelineInterval)) { context in
            let progress = order.shipmentProgress(at: context.date)
            let segments = ShipmentGeometry.routeSegments(
                from: route.origin,
                to: route.destination,
                fraction: progress
            )
            let dashPhase = animatedDashPhase(
                at: context.date,
                speed: 18,
                patternLength: 13
            )

            Map(initialPosition: cameraPosition) {
                if progress < 1 {
                    MapPolyline(coordinates: segments.remaining)
                        .stroke(
                            Color.brandPrimary.opacity(0.14),
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round
                            )
                        )

                    MapPolyline(coordinates: segments.remaining)
                        .stroke(
                            Color.brandPrimary.opacity(0.52),
                            style: StrokeStyle(
                                lineWidth: 2.5,
                                lineCap: .round,
                                dash: [4, 9],
                                dashPhase: dashPhase
                            )
                        )
                }

                if progress > 0 {
                    MapPolyline(coordinates: segments.traversed)
                        .stroke(
                            Color.brandPrimary.opacity(0.16),
                            style: StrokeStyle(
                                lineWidth: 8,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )

                    MapPolyline(coordinates: segments.traversed)
                        .stroke(
                            Color.brandPrimary,
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                }

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

                Annotation("Shipment", coordinate: segments.current) {
                    ShipmentMapMarker(
                        imageURL: order.items.first?.imageURL,
                        imageSize: 42
                    )
                }
                .annotationTitles(.hidden)
            }
            .mapStyle(
                .standard(
                    elevation: .flat,
                    emphasis: .muted,
                    pointsOfInterest: .excludingAll,
                    showsTraffic: false
                )
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(progress: progress))
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var cameraPosition: MapCameraPosition {
        .rect(MKMapRect(fitting: routeCoordinates).padded(by: 0.3))
    }

    private var timelineInterval: TimeInterval {
        reduceMotion ? 1 : 1 / 15
    }

    private func animatedDashPhase(
        at date: Date,
        speed: Double,
        patternLength: Double
    ) -> CGFloat {
        guard !reduceMotion else { return 0 }

        let phase = (date.timeIntervalSinceReferenceDate * speed)
            .truncatingRemainder(dividingBy: patternLength)
        return -CGFloat(phase)
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
