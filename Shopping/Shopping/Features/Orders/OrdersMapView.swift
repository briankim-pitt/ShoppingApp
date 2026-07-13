import MapKit
import SwiftUI

struct OrdersMapView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let shipments: [OrderShipment]

    init(orders: [VirtualOrder]) {
        shipments = OrderShipment.mapShipments(from: orders)
    }

    var body: some View {
        if !shipments.isEmpty {
            TimelineView(.periodic(from: .now, by: timelineInterval)) { context in
                let dashPhase = animatedDashPhase(
                    at: context.date,
                    speed: 16,
                    patternLength: 12
                )

                Map(initialPosition: initialPosition) {
                    ForEach(shipments) { shipment in
                        let progress = shipment.order.shipmentProgress(
                            at: context.date
                        )
                        let segments = shipment.routeSegments(at: context.date)

                        if progress < 1 {
                            MapPolyline(coordinates: segments.remaining)
                                .stroke(
                                    Color.brandPrimary.opacity(0.12),
                                    style: StrokeStyle(
                                        lineWidth: 3.5,
                                        lineCap: .round
                                    )
                                )

                            MapPolyline(coordinates: segments.remaining)
                                .stroke(
                                    Color.brandPrimary.opacity(0.48),
                                    style: StrokeStyle(
                                        lineWidth: 2.25,
                                        lineCap: .round,
                                        dash: [4, 8],
                                        dashPhase: dashPhase
                                    )
                                )
                        }

                        if progress > 0 {
                            MapPolyline(coordinates: segments.traversed)
                                .stroke(
                                    Color.brandPrimary.opacity(0.14),
                                    style: StrokeStyle(
                                        lineWidth: 7,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )

                            MapPolyline(coordinates: segments.traversed)
                                .stroke(
                                    Color.brandPrimary.opacity(0.85),
                                    style: StrokeStyle(
                                        lineWidth: 3,
                                        lineCap: .round,
                                        lineJoin: .round
                                    )
                                )
                        }

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
                            coordinate: segments.current
                        ) {
                            ShipmentMapMarker(
                                imageURL: shipment.order.items.first?.imageURL
                            )
                        }
                        .annotationTitles(.hidden)
                    }
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

    private var accessibilityLabel: String {
        "Map of \(shipments.count) shipment\(shipments.count == 1 ? "" : "s") in transit"
    }
}

#Preview {
    OrdersMapView(orders: PreviewData.orders)
        .padding()
}
