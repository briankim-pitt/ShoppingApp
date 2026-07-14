import SwiftUI

struct OrderDetailOverviewView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order overview")
                .font(.headline)

            HStack(spacing: 12) {
                OrderDetailMetricView(
                    title: "Total",
                    value: order.totalText,
                    showsCoin: true
                )

                OrderDetailMetricView(
                    title: "Items",
                    value: order.itemCount.formatted(),
                    systemImage: "shippingbox.fill"
                )
            }

            VStack(spacing: 12) {
                LabeledContent("Ordered") {
                    Text(
                        order.orderedAt,
                        format: .dateTime.month(.abbreviated).day().year()
                    )
                }

                if let estimatedDeliveryAt = order.estimatedDeliveryAt {
                    Divider()

                    LabeledContent("Estimated delivery") {
                        Text(
                            estimatedDeliveryAt,
                            format: .dateTime.month(.abbreviated).day()
                        )
                    }
                }
            }
            .font(.subheadline)
            .orderItemCardStyle()
        }
    }
}
