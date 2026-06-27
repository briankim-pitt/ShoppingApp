import SwiftUI

struct OrderTrackingStepView: View {
    let status: VirtualOrderStatus
    let event: VirtualOrderStatusEvent?
    let state: OrderTrackingStepState
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: markerImage)
                    .foregroundStyle(markerStyle)
                    .accessibilityHidden(true)

                if !isLast {
                    Rectangle()
                        .fill(connectorStyle)
                        .frame(width: 2, height: 32)
                        .accessibilityHidden(true)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(status.title)
                        .bold(state == .current)

                    if state == .current {
                        Text("Current")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let event {
                    Text(
                        event.occurredAt,
                        format: .dateTime
                            .month(.abbreviated)
                            .day()
                            .hour()
                            .minute()
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                } else {
                    Text("Waiting")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(accessibilityValue)
    }

    private var markerImage: String {
        switch state {
        case .completed:
            "checkmark.circle.fill"
        case .current:
            status.systemImage
        case .upcoming:
            "circle"
        }
    }

    private var markerStyle: AnyShapeStyle {
        switch state {
        case .completed, .current:
            AnyShapeStyle(.primary)
        case .upcoming:
            AnyShapeStyle(.tertiary)
        }
    }

    private var connectorStyle: AnyShapeStyle {
        state == .completed
            ? AnyShapeStyle(.primary)
            : AnyShapeStyle(.quaternary)
    }

    private var accessibilityValue: String {
        switch state {
        case .completed:
            "Completed"
        case .current:
            "Current status"
        case .upcoming:
            "Upcoming"
        }
    }
}
