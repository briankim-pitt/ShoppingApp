import SwiftUI

struct OrderTrackingTimeline: View {
    let order: VirtualOrder

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(order.trackingStatuses.enumerated()), id: \.element) {
                index, status in
                OrderTrackingStepView(
                    status: status,
                    event: order.event(for: status),
                    state: state(for: status),
                    isLast: index == order.trackingStatuses.count - 1
                )
            }
        }
    }

    private func state(for status: VirtualOrderStatus) -> OrderTrackingStepState {
        if status == order.status {
            return .current
        }

        if order.event(for: status) != nil {
            return .completed
        }

        return .upcoming
    }
}
