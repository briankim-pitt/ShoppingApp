import SwiftUI

struct OrderDetailOverviewView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order overview")
                .font(.title2.bold())

            HStack(spacing: 12) {
                OrderDetailMetricView(
                    title: "Total",
                    value: order.totalText,
                    systemImage: "w.circle.fill"
                )

                OrderDetailMetricView(
                    title: "Items",
                    value: order.itemCount.formatted(),
                    systemImage: "shippingbox.fill"
                )
            }

            LabeledContent("Ordered") {
                Text(
                    order.orderedAt,
                    format: .dateTime.month(.abbreviated).day().year()
                )
            }

            if let estimatedDeliveryAt = order.estimatedDeliveryAt {
                LabeledContent("Estimated delivery") {
                    Text(
                        estimatedDeliveryAt,
                        format: .dateTime.month(.abbreviated).day()
                    )
                }
            }
        }
    }
}
