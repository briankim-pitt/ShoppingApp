import SwiftUI

struct DailyCheckInCard: View {
    let status: DailyCheckInStatus?
    let isClaiming: Bool
    let claim: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text("Daily Check-in")
                    .font(.headline)

                Spacer()

                HStack(spacing: 6) {
                    Text("+\(rewardAmount.wanderCoinNumber)")
                        .font(.headline)

                    WanderCoinIcon(size: 18)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(status?.claimedToday == true ? claimedMessage : availableMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.86))

                if let status, status.streakCount > 0 {
                    Label(
                        "\(status.streakCount)-day streak",
                        systemImage: "flame.fill"
                    )
                    .font(.footnote)
                    .bold()
                    .foregroundStyle(.white)
                }
            }

            Button(
                buttonTitle,
                systemImage: buttonSystemImage,
                action: claim
            )
            .font(.subheadline)
            .bold()
            .foregroundStyle(Color.brandPrimary)
            .frame(maxWidth: .infinity)
            .buttonStyle(.borderedProminent)
            .tint(.white)
            .disabled(status == nil || status?.claimedToday == true || isClaiming)
        }
        .foregroundStyle(.white)
        .padding(18)
        .background(Color.brandPrimary, in: .rect(cornerRadius: 18))
        .shadow(
            color: Color.brandPrimary.opacity(0.24),
            radius: 14,
            y: 6
        )
        .accessibilityElement(children: .contain)
    }

    private var rewardAmount: Decimal {
        status?.rewardAmount ?? 100
    }

    private var availableMessage: String {
        "Check in today to add bonus WanderCoins to your wallet."
    }

    private var claimedMessage: String {
        "Today’s bonus is in your wallet. Come back tomorrow!"
    }

    private var buttonTitle: String {
        if isClaiming {
            "Checking In…"
        } else if status?.claimedToday == true {
            "Claimed Today"
        } else {
            "Check In"
        }
    }

    private var buttonSystemImage: String {
        status?.claimedToday == true ? "checkmark" : "sparkles"
    }
}
