import SwiftUI

struct OrdersView: View {
    @Environment(AppModel.self) private var appModel
    @State private var viewModel = OrdersViewModel()
    @State private var searchText = ""
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var selectedItemID: UUID?
    @State private var itemPendingDeletion: OrderBoardItem?
    @State private var isShowingDeleteConfirmation = false
    @State private var isArrangingBoard = false
    @State private var boardPositions = OrderBoardPositionStore.load()
    @State private var originalBoardPositions: [UUID: OrderBoardPosition] = [:]
    @State private var boardVisibility = OrderBoardVisibilityStore.load()
    @Namespace private var orderTransition

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        OrdersContentView(
                            viewModel: viewModel,
                            boardItems: boardItems,
                            boardPositions: $boardPositions,
                            isArrangingBoard: isArrangingBoard,
                            transitionNamespace: orderTransition,
                            retryAction: retry,
                            selectionAction: selectItem,
                            moveAction: beginArrangingBoard,
                            hideAction: hideItem,
                            deleteAction: requestDeletion
                        )
                    }
                    .padding(.top, isArrangingBoard ? 8 : 62)
                    .padding(.bottom, 32)
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newValue in
                    guard !isRefreshing else { return }
                    scrollOffset = newValue < 0 ? -newValue : 0
                }
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .brandPageBackground()
                .refreshable(action: refresh)

                OrdersSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .opacity(isArrangingBoard ? 0 : searchBarOpacity)
                    .allowsHitTesting(!isArrangingBoard && searchBarOpacity > 0.05)
            }
            .appPageTitle(isArrangingBoard ? "Arrange Board" : "Orders")
            .toolbar(isArrangingBoard ? .hidden : .visible, for: .tabBar)
            .toolbar {
                if isArrangingBoard {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(
                            "Cancel",
                            systemImage: "xmark",
                            action: cancelArrangingBoard
                        )
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button(
                            "Done",
                            systemImage: "checkmark",
                            action: finishArrangingBoard
                        )
                    }
                } else {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button(
                            "Arrange Board",
                            systemImage: "square.grid.3x3",
                            action: beginArrangingBoard
                        )
                        .disabled(boardItems.isEmpty)

                        if !boardVisibility.hiddenItemIDs.isEmpty {
                            Menu("Board Options", systemImage: "ellipsis") {
                                Button(
                                    "Restore Hidden Items",
                                    systemImage: "eye",
                                    action: restoreHiddenItems
                                )
                            }
                        }
                    }
                }
            }
            .navigationDestination(item: $selectedItemID) { itemID in
                if let boardItem = allBoardItems.first(where: { $0.id == itemID }) {
                    OrderDetailView(
                        orderID: boardItem.order.id,
                        heroItemID: itemID,
                        viewModel: viewModel
                    )
                    .navigationTransition(
                        .zoom(sourceID: itemID, in: orderTransition)
                    )
                }
            }
            .alert(
                "Delete from Board?",
                isPresented: $isShowingDeleteConfirmation,
                presenting: itemPendingDeletion
            ) { boardItem in
                Button("Delete", role: .destructive) {
                    deleteItem(boardItem)
                }
                Button("Cancel", role: .cancel) {}
            } message: { boardItem in
                Text("\(boardItem.item.title) will be removed from your board.")
            }
            .task {
                await viewModel.observe(using: appModel)
            }
        }
    }

    private var allBoardItems: [OrderBoardItem] {
        viewModel.orders.flatMap { order in
            order.items.map { item in
                OrderBoardItem(order: order, item: item)
            }
        }
        .sorted { left, right in
            if left.order.orderedAt == right.order.orderedAt {
                return left.item.createdAt > right.item.createdAt
            }
            return left.order.orderedAt > right.order.orderedAt
        }
    }

    private var boardItems: [OrderBoardItem] {
        let visibleItems = allBoardItems.filter { boardItem in
            !boardVisibility.hiddenItemIDs.contains(boardItem.id)
                && !boardVisibility.removedItemIDs.contains(boardItem.id)
        }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return visibleItems }

        return visibleItems.filter { boardItem in
            boardItem.item.title.localizedCaseInsensitiveContains(query)
                || boardItem.order.status.title.localizedCaseInsensitiveContains(query)
        }
    }

    private var searchBarOpacity: CGFloat {
        guard !isRefreshing else { return 0 }
        return max(1 - (scrollOffset / 56), 0)
    }

    private func selectItem(_ itemID: UUID) {
        selectedItemID = itemID
    }

    private func beginArrangingBoard() {
        originalBoardPositions = boardPositions
        searchText = ""
        withAnimation(.snappy) {
            isArrangingBoard = true
        }
    }

    private func cancelArrangingBoard() {
        boardPositions = originalBoardPositions
        OrderBoardPositionStore.save(boardPositions)
        withAnimation(.snappy) {
            isArrangingBoard = false
        }
    }

    private func finishArrangingBoard() {
        OrderBoardPositionStore.save(boardPositions)
        originalBoardPositions = [:]
        withAnimation(.snappy) {
            isArrangingBoard = false
        }
    }

    private func hideItem(_ boardItem: OrderBoardItem) {
        withAnimation(.snappy) {
            boardVisibility.hiddenItemIDs.insert(boardItem.id)
        }
        OrderBoardVisibilityStore.save(boardVisibility)
    }

    private func requestDeletion(_ boardItem: OrderBoardItem) {
        itemPendingDeletion = boardItem
        isShowingDeleteConfirmation = true
    }

    private func deleteItem(_ boardItem: OrderBoardItem) {
        withAnimation(.snappy) {
            boardVisibility.hiddenItemIDs.remove(boardItem.id)
            boardVisibility.removedItemIDs.insert(boardItem.id)
            boardPositions.removeValue(forKey: boardItem.id)
        }
        OrderBoardVisibilityStore.save(boardVisibility)
        OrderBoardPositionStore.save(boardPositions)
        itemPendingDeletion = nil
    }

    private func restoreHiddenItems() {
        withAnimation(.snappy) {
            boardVisibility.hiddenItemIDs.removeAll()
        }
        OrderBoardVisibilityStore.save(boardVisibility)
    }

    private func retry() {
        Task {
            await viewModel.retry(using: appModel)
        }
    }

    private func refresh() async {
        withAnimation(.easeInOut(duration: 0.15)) {
            isRefreshing = true
        }
        await viewModel.refresh(using: appModel)
        withAnimation(.easeInOut(duration: 0.15)) {
            isRefreshing = false
            scrollOffset = 0
        }
    }
}

#Preview {
    OrdersView()
        .environment(PreviewData.readyAppModel)
}
