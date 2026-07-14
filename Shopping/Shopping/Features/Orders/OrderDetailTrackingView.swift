import SwiftUI

struct OrderDetailTrackingView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking")
                .font(.headline)

            OrderTrackingTimeline(order: order)
                .orderItemCardStyle()
        }
    }
}
