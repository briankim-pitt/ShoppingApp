import SwiftUI

struct AddFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                FriendsInvitationContent(
                    searchText: $searchText,
                    showsFindFriendsSection: true
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollBounceBehavior(.always)
            .scrollDismissesKeyboard(.interactively)
            .brandPageBackground()
            .navigationTitle("Add Friends")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    AddFriendsView()
}
