import SwiftUI

struct OrdersBoardView: View {
    private let bottomBuffer: CGFloat = 180

    let items: [OrderBoardItem]
    @Binding var positions: [UUID: OrderBoardPosition]
    let isArranging: Bool
    let transitionNamespace: Namespace.ID
    let selectionAction: (UUID) -> Void
    let moveAction: () -> Void
    let hideAction: (OrderBoardItem) -> Void
    let deleteAction: (OrderBoardItem) -> Void

    @State private var stackingOrder = OrderBoardPositionStore.loadStackingOrder()

    var body: some View {
        GeometryReader { geometry in
            let itemBoardSize = CGSize(
                width: geometry.size.width,
                height: max(geometry.size.height - bottomBuffer, 1)
            )

            ZStack {
                OrderBoardDotMatrix()

                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if isArranging {
                        OrderBoardEditorTile(
                            boardItem: item,
                            position: positionBinding(for: item.id, index: index),
                            boardSize: itemBoardSize,
                            interactionAction: {
                                bringToFront(item.id)
                            },
                            savePositionAction: savePositions
                        )
                        .zIndex(stackingRank(for: item.id, fallback: index))
                    } else {
                        OrderBoardTile(
                            boardItem: item,
                            transitionNamespace: transitionNamespace,
                            interactionAction: {
                                bringToFront(item.id)
                            },
                            selectionAction: selectionAction,
                            moveAction: moveAction,
                            hideAction: hideAction,
                            deleteAction: deleteAction
                        )
                        .position(
                            displayPosition(
                                for: item,
                                at: index,
                                in: itemBoardSize
                            )
                        )
                        .zIndex(stackingRank(for: item.id, fallback: index))
                    }
                }
            }
            .coordinateSpace(.named("ordersBoard"))
        }
        .frame(height: boardHeight)
        .onAppear {
            seedMissingPositions()
            seedStackingOrder()
        }
        .onChange(of: items.map(\.id)) {
            seedMissingPositions()
            seedStackingOrder()
        }
    }

    private var boardHeight: CGFloat {
        let rows = ceil(Double(items.count) / 3)
        return max(CGFloat(rows) * 148, 540) + bottomBuffer
    }

    private func positionBinding(
        for id: UUID,
        index: Int
    ) -> Binding<OrderBoardPosition> {
        Binding {
            positions[id] ?? OrderBoardPosition.initial(
                for: id,
                at: index,
                itemCount: items.count
            )
        } set: { newPosition in
            positions[id] = newPosition.clamped()
        }
    }

    private func seedMissingPositions() {
        var didChange = false
        for (index, item) in items.enumerated() where positions[item.id] == nil {
            positions[item.id] = OrderBoardPosition.initial(
                for: item.id,
                at: index,
                itemCount: items.count
            )
            didChange = true
        }

        if didChange {
            savePositions()
        }
    }

    private func savePositions() {
        OrderBoardPositionStore.save(positions)
    }

    private func seedStackingOrder() {
        var didChange = false
        for item in items where !stackingOrder.contains(item.id) {
            stackingOrder.append(item.id)
            didChange = true
        }

        if didChange {
            OrderBoardPositionStore.saveStackingOrder(stackingOrder)
        }
    }

    private func bringToFront(_ id: UUID) {
        stackingOrder.removeAll { $0 == id }
        stackingOrder.append(id)
        OrderBoardPositionStore.saveStackingOrder(stackingOrder)
    }

    private func stackingRank(for id: UUID, fallback: Int) -> Double {
        Double(stackingOrder.firstIndex(of: id) ?? fallback)
    }

    private func displayPosition(
        for item: OrderBoardItem,
        at index: Int,
        in boardSize: CGSize
    ) -> CGPoint {
        let position = positions[item.id] ?? OrderBoardPosition.initial(
            for: item.id,
            at: index,
            itemCount: items.count
        )
        let horizontalTravel = max(boardSize.width - item.boardTileSize, 1)
        let verticalTravel = max(boardSize.height - item.boardTileSize, 1)

        return CGPoint(
            x: item.boardTileSize / 2 + position.x * horizontalTravel,
            y: item.boardTileSize / 2 + position.y * verticalTravel
        )
    }
}
