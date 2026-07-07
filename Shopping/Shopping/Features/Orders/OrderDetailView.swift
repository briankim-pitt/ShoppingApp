import SwiftUI

struct OrderDetailView: View {
    @Environment(AppModel.self) private var appModel

    let orderID: UUID
    @Bindable var viewModel: OrdersViewModel

    var body: some View {
        Group {
            if let order = viewModel.orders.first(where: { $0.id == orderID }) {
                List {
                    Section {
                        LabeledContent("Status") {
                            Label(
                                order.status.title,
                                systemImage: order.status.systemImage
                            )
                        }

                        LabeledContent("Total", value: order.totalText)

                        LabeledContent("Ordered") {
                            Text(
                                order.orderedAt,
                                format: .dateTime
                                    .month(.abbreviated)
                                    .day()
                                    .year()
                                    .hour()
                                    .minute()
                            )
                        }

                        if let estimatedDeliveryAt = order.estimatedDeliveryAt {
                            LabeledContent("Estimated delivery") {
                                Text(
                                    estimatedDeliveryAt,
                                    format: .dateTime
                                        .month(.abbreviated)
                                        .day()
                                        .hour()
                                        .minute()
                                )
                            }
                        }

                        if let nextStatusAt = order.nextStatusAt {
                            LabeledContent("Next update") {
                                Text(nextStatusAt, style: .relative)
                            }
                        }
                    }
                    .brandListRow()

                    if let route = order.shipmentRoute {
                        Section("Shipment") {
                            VStack(alignment: .leading, spacing: 8) {
                                OrderTrackingMapView(order: order, route: route)

                                Text(
                                    "Simulated route from \(route.originName) to \(route.destinationName)"
                                )
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .brandListRow()
                    }

                    Section("Items") {
                        ForEach(order.items) { item in
                            OrderItemRow(item: item)
                        }
                    }
                    .brandListRow()

                    Section("Tracking") {
                        OrderTrackingTimeline(order: order)
                            .padding(.vertical, 4)
                    }
                    .brandListRow()
                }
                .refreshable {
                    await viewModel.refresh(using: appModel)
                }
                .brandPageBackground()
            } else {
                ContentUnavailableView {
                    BrandEmptyStateLabel(
                        title: "Order Unavailable",
                        systemImage: "shippingbox"
                    )
                } description: {
                    Text("This order is no longer available.")
                }
            }
        }
        .appPageTitle("Order Details")
    }
}
