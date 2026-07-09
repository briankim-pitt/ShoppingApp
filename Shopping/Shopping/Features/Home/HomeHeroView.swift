import SwiftUI

struct HomeHeroView: View {
    let greeting: String
    let displayName: String?
    let walletBalance: Decimal
    let dailyCheckInStatus: DailyCheckInStatus?
    let isClaimingDailyBonus: Bool
    let claimDailyBonus: () -> Void
    let addCoin: () -> Void
    let scrollOffset: CGFloat

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text(heading)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Label {
                        Text(walletBalance.wanderCoinText)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    } icon: {
                        WanderCoinIcon(size: 18)
                    }
                    .font(.headline)
                    .animation(.snappy(duration: 0.28), value: walletBalance)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.72), in: .capsule)
                }

                Button(
                    checkInTitle,
                    systemImage: checkInSystemImage,
                    action: claimDailyBonus
                )
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.capsule)
                .tint(.white)
                .foregroundStyle(Color.brandPrimary)
                .disabled(
                    dailyCheckInStatus == nil ||
                        dailyCheckInStatus?.claimedToday == true ||
                        isClaimingDailyBonus
                )
            }
            .padding(.horizontal, 28)
            .offset(y: parallaxOffset)
            .opacity(fadeOpacity)
        }
        .containerRelativeFrame(.horizontal)
        .frame(height: 330)
        .contentShape(.rect)
        .simultaneousGesture(
            TapGesture().onEnded(addCoin)
        )
        .accessibilityElement(children: .contain)
    }

    private var heading: String {
        guard let displayName, !displayName.isEmpty else {
            return greeting
        }

        return "\(greeting), \(displayName)"
    }

    private var checkInTitle: String {
        if isClaimingDailyBonus {
            "Checking In"
        } else if dailyCheckInStatus?.claimedToday == true {
            "Claimed Today"
        } else {
            "Daily Check-in"
        }
    }

    private var checkInSystemImage: String {
        dailyCheckInStatus?.claimedToday == true ? "checkmark" : "sparkles"
    }

    private var fadeOpacity: Double {
        let progress = min(max(scrollOffset / 190, 0), 1)
        return Double(1 - progress)
    }

    private var parallaxOffset: CGFloat {
        -max(scrollOffset, 0) * 0.32
    }
}
