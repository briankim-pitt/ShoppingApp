import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var orders: [VirtualOrder] = []
    @State private var isClaimingDailyBonus = false
    @State private var isShowingCheckInError = false
    @State private var checkInErrorMessage = ""
    @State private var isShowingSettings = false

    private var recentOrders: [VirtualOrder] {
        Array(orders.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingSection
                    DailyCheckInCard(
                        status: appModel.dailyCheckInStatus,
                        isClaiming: isClaimingDailyBonus,
                        claim: claimDailyBonus
                    )
                    statsSection

                    if !recentOrders.isEmpty {
                        recentOrdersSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .brandPageBackground()
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    WanderCartLogoMark()
                        .frame(width: 36, height: 30)
                }
                .sharedBackgroundVisibility(.hidden)

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") {
                        isShowingSettings = true
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
            .task {
                await loadOrders()
            }
            .refreshable {
                await appModel.refreshWallet()
                await loadOrders()
            }
            .alert(
                "Check-in Unavailable",
                isPresented: $isShowingCheckInError
            ) {
            } message: {
                Text(checkInErrorMessage)
            }
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3.weight(.semibold))

            HStack(spacing: 6) {
                Text("You have")
                    .foregroundStyle(.secondary)

                Text(walletBalance.wanderCoinNumber)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)

                WanderCoinIcon(size: 18)
            }
            .font(.subheadline)
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Stats")
                    .font(.headline)

                Spacer()

                Text("All Time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 10),
                    count: 3
                ),
                spacing: 10
            ) {
                HomeStatTile(
                    title: "In Cart",
                    value: "\(appModel.cart.itemCount)",
                    systemImage: "cart"
                )

                HomeStatTile(
                    title: "Orders",
                    value: "\(orders.count)",
                    systemImage: "shippingbox"
                )

                HomeStatTile(
                    title: "Coins Spent",
                    value: coinsSpent.wanderCoinNumber,
                    showsCoin: true
                )
            }
        }
    }

    private var recentOrdersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Orders")
                    .font(.headline)

                Spacer()

                Button("See All") {
                    appModel.selectedTab = .orders
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }

            ForEach(recentOrders) { order in
                Button {
                    appModel.selectedTab = .orders
                } label: {
                    OrderRow(order: order)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var walletBalance: Decimal {
        appModel.wallet?.balance.amount ?? 0
    }

    private var coinsSpent: Decimal {
        orders
            .filter { $0.status != .cancelled }
            .reduce(Decimal.zero) { $0 + $1.totalAmount }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)

        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private func loadOrders() async {
        if let orders = try? await appModel.listOrders() {
            self.orders = orders
        }
    }

    private func claimDailyBonus() {
        guard !isClaimingDailyBonus else { return }

        Task {
            isClaimingDailyBonus = true
            defer { isClaimingDailyBonus = false }

            do {
                try await appModel.claimDailyCheckIn()
            } catch {
                checkInErrorMessage = error.localizedDescription
                isShowingCheckInError = true
            }
        }
    }
}

private struct HomeStatTile: View {
    let title: String
    let value: String
    var systemImage: String?
    var showsCoin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(Color.brandPrimary)
                } else if showsCoin {
                    WanderCoinIcon(size: 18)
                }

                Spacer(minLength: 0)
            }

            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding(12)
        .background(Color.brandPurpleSurface, in: .rect(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    HomeView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    HomeView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.dark)
}
