import SwiftUI

struct OrderDetailView: View {
    @Environment(AppModel.self) private var appModel

    let orderID: UUID
    let heroItemID: UUID?
    @Bindable var viewModel: OrdersViewModel

    init(
        orderID: UUID,
        heroItemID: UUID? = nil,
        viewModel: OrdersViewModel
    ) {
        self.orderID = orderID
        self.heroItemID = heroItemID
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if let order = viewModel.orders.first(where: { $0.id == orderID }) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 28) {
                        OrderDetailHeroView(
                            order: order,
                            selectedItemID: heroItemID
                        )

                        OrderDetailOverviewView(order: order)

                        if let route = order.shipmentRoute {
                            OrderDetailShipmentView(order: order, route: route)
                        }

                        OrderDetailItemsView(order: order)

                        OrderDetailTrackingView(order: order)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
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
