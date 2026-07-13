import SwiftUI

struct OrdersContentView: View {
    let viewModel: OrdersViewModel
    let boardItems: [OrderBoardItem]
    @Binding var boardPositions: [UUID: OrderBoardPosition]
    let isArrangingBoard: Bool
    let transitionNamespace: Namespace.ID
    let retryAction: () -> Void
    let selectionAction: (UUID) -> Void
    let moveAction: () -> Void
    let hideAction: (OrderBoardItem) -> Void
    let deleteAction: (OrderBoardItem) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.orders.isEmpty {
                AppLoadingIndicator(size: 36)
                    .containerRelativeFrame(.vertical)
            } else if let errorMessage = viewModel.errorMessage,
                      viewModel.orders.isEmpty {
                ContentUnavailableView {
                    BrandEmptyStateLabel(
                        title: "Couldn't Load Orders",
                        systemImage: "wifi.exclamationmark"
                    )
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button(
                        "Try Again",
                        systemImage: "arrow.clockwise",
                        action: retryAction
                    )
                    .buttonStyle(.glassProminent)
                    .tint(Color.brandPrimary)
                }
                .containerRelativeFrame(.vertical)
            } else if viewModel.orders.isEmpty {
                ContentUnavailableView {
                    BrandEmptyStateLabel(
                        title: "No Orders Yet",
                        systemImage: "shippingbox"
                    )
                } description: {
                    Text("Your virtual purchases will appear here.")
                }
                .containerRelativeFrame(.vertical)
            } else if boardItems.isEmpty {
                ContentUnavailableView {
                    Label(
                        "No Matching Orders",
                        systemImage: "magnifyingglass"
                    )
                } description: {
                    Text("Try a different product name or status.")
                }
                .containerRelativeFrame(.vertical)
            } else {
                if let errorMessage = viewModel.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Color.brandAccentCoral)
                        .padding(.horizontal)
                }

                OrdersBoardView(
                    items: boardItems,
                    positions: $boardPositions,
                    isArranging: isArrangingBoard,
                    transitionNamespace: transitionNamespace,
                    selectionAction: selectionAction,
                    moveAction: moveAction,
                    hideAction: hideAction,
                    deleteAction: deleteAction
                )
            }
        }
    }
}
