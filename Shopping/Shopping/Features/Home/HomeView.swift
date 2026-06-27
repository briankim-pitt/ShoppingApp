import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                if let wallet = appModel.wallet {
                    Section("Virtual Wallet") {
                        LabeledContent("Balance", value: wallet.balance.formatted)
                        LabeledContent("Home currency", value: wallet.balance.currencyCode)
                    }
                }

                Section {
                    ContentUnavailableView {
                        Label("Your Storefront", systemImage: "bag")
                    } description: {
                        Text("Product importing is the next vertical slice.")
                    }
                }
            }
            .appPageTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign Out", systemImage: "rectangle.portrait.and.arrow.right") {
                        Task {
                            await appModel.signOut()
                        }
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .refreshable {
                await appModel.refreshWallet()
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(PreviewData.readyAppModel)
}
