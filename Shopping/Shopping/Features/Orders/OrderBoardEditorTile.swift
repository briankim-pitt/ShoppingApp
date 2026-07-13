import SwiftUI

struct OrderBoardEditorTile: View {
    let boardItem: OrderBoardItem
    @Binding var position: OrderBoardPosition
    let boardSize: CGSize
    let savePositionAction: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @GestureState private var dragTranslation = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        OrderBoardTileImage(item: boardItem.item)
            .frame(
                width: boardItem.boardTileSize,
                height: boardItem.boardTileSize
            )
            .rotationEffect(
                .degrees(isDragging ? 0 : boardItem.boardTileRotation)
            )
            .scaleEffect(isDragging && !reduceMotion ? 1.08 : 1)
            .shadow(
                color: .black.opacity(isDragging ? 0.2 : 0.09),
                radius: isDragging ? 18 : 9,
                y: isDragging ? 10 : 5
            )
            .position(displayPosition)
            .zIndex(isDragging ? 1 : 0)
            .highPriorityGesture(dragGesture)
            .sensoryFeedback(.impact(weight: .medium), trigger: isDragging)
            .accessibilityLabel(boardItem.item.title)
            .accessibilityHint("Drag to reposition on the board.")
            .animation(.snappy(duration: 0.22), value: isDragging)
    }

    private var displayPosition: CGPoint {
        let halfTile = boardItem.boardTileSize / 2
        let baseX = halfTile + position.x * horizontalTravel
        let baseY = halfTile + position.y * verticalTravel

        return CGPoint(
            x: min(
                max(baseX + dragTranslation.width, halfTile),
                boardSize.width - halfTile
            ),
            y: min(
                max(baseY + dragTranslation.height, halfTile),
                boardSize.height - halfTile
            )
        )
    }

    private var horizontalTravel: CGFloat {
        max(boardSize.width - boardItem.boardTileSize, 1)
    }

    private var verticalTravel: CGFloat {
        max(boardSize.height - boardItem.boardTileSize, 1)
    }

    private var dragGesture: some Gesture {
        DragGesture(
            minimumDistance: 0,
            coordinateSpace: .named("ordersBoard")
        )
        .updating($dragTranslation) { value, translation, _ in
            translation = value.translation
        }
        .onChanged { _ in
            guard !isDragging else { return }
            isDragging = true
        }
        .onEnded(finishDrag)
    }

    private func finishDrag(_ value: DragGesture.Value) {
        guard isDragging else { return }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            position = OrderBoardPosition(
                x: position.x + value.translation.width / horizontalTravel,
                y: position.y + value.translation.height / verticalTravel
            ).clamped()
        }

        isDragging = false
        savePositionAction()
    }
}
