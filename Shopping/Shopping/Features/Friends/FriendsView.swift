import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("No Friends Yet", systemImage: "person.2")
            } description: {
                Text("Friends and their activity will appear here.")
            }
            .appPageTitle("Friends")
        }
    }
}

#Preview {
    FriendsView()
}
