import Foundation
import SwiftUI

struct AddFriendsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView {
                        BrandEmptyStateLabel(
                            title: "Find Friends",
                            systemImage: "person.badge.plus"
                        )
                    } description: {
                        Text("Search for someone by username.")
                    }
                    .containerRelativeFrame(.vertical)
                } else {
                    ContentUnavailableView.search
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollBounceBehavior(.always)
            .brandPageBackground()
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by username"
            )
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
