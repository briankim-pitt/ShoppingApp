import SwiftUI

struct OrderDetailTrackingView: View {
    let order: VirtualOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tracking")
                .font(.title2.bold())

            OrderTrackingTimeline(order: order)
                .padding(16)
                .background(Color.brandPurpleSurface, in: .rect(cornerRadius: 16))
        }
    }
}
