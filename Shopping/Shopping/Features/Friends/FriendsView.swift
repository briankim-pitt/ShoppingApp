import Foundation
import SwiftUI

struct FriendsView: View {
    @State private var searchText = ""
    @State private var isShowingAddFriends = false
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
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .brandPageBackground()

                FriendsSearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
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
}

#Preview {
    FriendsView()
}
