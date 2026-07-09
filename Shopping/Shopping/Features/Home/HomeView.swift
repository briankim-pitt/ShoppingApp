import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel
    @State private var orders: [VirtualOrder] = []
    @State private var isClaimingDailyBonus = false
    @State private var isShowingCheckInError = false
    @State private var checkInErrorMessage = ""
    @State private var isShowingSettings = false
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var productTransition

    private var recentOrders: [VirtualOrder] {
        Array(orders.prefix(3))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.brandBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HomeHeroView(
                            greeting: greeting,
                            displayName: displayName,
                            walletBalance: walletBalance,
                            dailyCheckInStatus: appModel.dailyCheckInStatus,
                            isClaimingDailyBonus: isClaimingDailyBonus,
                            claimDailyBonus: claimDailyBonus,
                            addCoin: appModel.addPreviewCoin,
                            scrollOffset: scrollOffset
                        )
                        .padding(.horizontal, -20)
                        .padding(.top, -12)

                        statsSection

                        if !appModel.recentlyViewed.products.isEmpty {
                            recentlyViewedSection
                        }

                        if !recentOrders.isEmpty {
                            recentOrdersSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .background(alignment: .top) {
                        HomeAnimatedGradient()
                            .frame(height: 640)
                            .padding(.horizontal, -32)
                            .offset(y: -34)
                            .allowsHitTesting(false)
                    }
                }
                .scrollContentBackground(.hidden)
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newValue in
                    scrollOffset = newValue
                }
            }
            .navigationDestination(for: Product.self) { product in
                ProductDetailView(product: product)
                    .navigationTransition(
                        .zoom(sourceID: product.id, in: productTransition)
                    )
            }
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
            .task {
                await appModel.loadUserEmail()
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
            // Applied after .refreshable so Settings, presented below, sits
            // outside its \.refresh environment and has no pull-to-refresh
            // of its own.
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
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

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recently Viewed")
                    .font(.headline)

                Spacer()

                Button("Clear") {
                    appModel.recentlyViewed.clear()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandPrimary)
            }

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(appModel.recentlyViewed.products) { product in
                        NavigationLink(value: product) {
                            RecentlyViewedProductCard(
                                product: product,
                                transitionNamespace: productTransition
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollClipDisabled()
            .scrollIndicators(.hidden)
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

    private var displayName: String? {
        guard let email = appModel.userEmail?.split(separator: "@").first else {
            return nil
        }

        let cleaned = email
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }

        return cleaned
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
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
        .background(Color(uiColor: .systemBackground), in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brandPrimary.opacity(0.08))
        }
        .shadow(color: .black.opacity(0.035), radius: 14, y: 8)
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
