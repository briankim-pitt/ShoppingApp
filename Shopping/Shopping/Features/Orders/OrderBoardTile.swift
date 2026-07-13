import SwiftUI

struct OrderBoardTile: View {
    let boardItem: OrderBoardItem
    let transitionNamespace: Namespace.ID
    let selectionAction: (UUID) -> Void
    let moveAction: () -> Void
    let hideAction: (OrderBoardItem) -> Void
    let deleteAction: (OrderBoardItem) -> Void

    var body: some View {
        Button(action: selectItem) {
            OrderBoardTileImage(item: boardItem.item)
                .frame(
                    width: boardItem.boardTileSize,
                    height: boardItem.boardTileSize
                )
                .rotationEffect(.degrees(boardItem.boardTileRotation))
                .shadow(color: .black.opacity(0.09), radius: 9, y: 5)
        }
        .buttonStyle(.plain)
        .matchedTransitionSource(id: boardItem.id, in: transitionNamespace)
        .contextMenu {
            Button("Move", systemImage: "arrow.up.and.down.and.arrow.left.and.right") {
                moveAction()
            }

            Button("Hide", systemImage: "eye.slash") {
                hideAction(boardItem)
            }

            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteAction(boardItem)
            }
        }
        .accessibilityLabel(boardItem.item.title)
        .accessibilityHint("Opens order details. Touch and hold for board options.")
    }

    private func selectItem() {
        selectionAction(boardItem.id)
    }
}
