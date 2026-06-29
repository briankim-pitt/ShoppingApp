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
                        ContentUnavailableView {
                            BrandEmptyStateLabel(
                                title: "No Friends Yet",
                                systemImage: "person.2"
                            )
                        } description: {
                            Text("Friends and their activity will appear here.")
                        }
                        .containerRelativeFrame(.vertical)
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
