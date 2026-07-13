import Foundation
import SwiftUI

struct FriendsView: View {
    @State private var searchText = ""
    @State private var isShowingAddFriends = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    @Namespace private var addFriendsTransition

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        BrandedActionEmptyState(
                            imageName: "friend.symbols",
                            title: "No Friends Yet",
                            description: "Add friends to see what they’re shopping for—without actually buying.",
                            actionTitle: "Add Friends",
                            actionSystemImage: "person.badge.plus",
                            action: showAddFriends
                        )
                        .containerRelativeFrame(.vertical)
                        .padding(.top, 44)
                    } else {
                        ContentUnavailableView.search
                            .containerRelativeFrame(.vertical)
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top
                } action: { _, newValue in
                    guard !isRefreshing else { return }
                    scrollOffset = newValue < 0 ? -newValue : 0
                }
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .refreshable {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isRefreshing = true
                    }
                    await Task.yield()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isRefreshing = false
                        scrollOffset = 0
                    }
                }
                .brandPageBackground()

                FriendsSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .opacity(searchBarOpacity)
                    .allowsHitTesting(searchBarOpacity > 0.05)
            }
            .appPageTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: showAddFriends) {
                        Label("Add Friends", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(Color.brandPrimary)
                    .matchedTransitionSource(
                        id: "addFriends",
                        in: addFriendsTransition
                    )
                }
            }
            .sheet(isPresented: $isShowingAddFriends) {
                AddFriendsView()
                    .presentationDetents([.medium, .large])
                    .navigationTransition(
                        .zoom(
                            sourceID: "addFriends",
                            in: addFriendsTransition
                        )
                    )
            }
        }
    }

    private func showAddFriends() {
        isShowingAddFriends = true
    }

    private var searchBarOpacity: CGFloat {
        guard !isRefreshing else { return 0 }
        return max(1 - (scrollOffset / 56), 0)
    }
}

#Preview {
    FriendsView()
}
