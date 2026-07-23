import SwiftUI
import UIKit

extension Color {
    static let brandBackground = Color(
        uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(
                    red: 13 / 255,
                    green: 14 / 255,
                    blue: 17 / 255,
                    alpha: 1
                )
            }

            return .white
        }
    )

    static let brandPrimary = Color(
        red: 123 / 255,
        green: 77 / 255,
        blue: 255 / 255
    )

    static let brandAction = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : .black
        }
    )

    static let brandActionForeground = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : .white
        }
    )

    static let brandPurpleLight = Color(
        red: 185 / 255,
        green: 156 / 255,
        blue: 255 / 255
    )

    static let brandPurpleSurface = Color(
        uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(
                    red: 29 / 255,
                    green: 25 / 255,
                    blue: 38 / 255,
                    alpha: 1
                )
            }

            return UIColor(
                red: 243 / 255,
                green: 240 / 255,
                blue: 255 / 255,
                alpha: 1
            )
        }
    )

    static let brandSuccess = Color(
        red: 34 / 255,
        green: 197 / 255,
        blue: 94 / 255
    )

    static let brandAccentCoral = Color(
        red: 255 / 255,
        green: 107 / 255,
        blue: 138 / 255
    )

    static let brandBorder = Color(
        red: 229 / 255,
        green: 231 / 255,
        blue: 235 / 255
    )
}

struct WanderCoinIcon: View {
    let size: CGFloat

    init(size: CGFloat = 18) {
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(Color.brandPrimary)
            .overlay {
                Text("W")
                    .font(
                        .system(
                            size: size * 0.48,
                            weight: .bold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct WanderCartWordmark: View {
    var body: some View {
        HStack(spacing: 5) {
            WanderCartLogoMark()
                .frame(width: 44, height: 36)

            Text("anderCart")
                .font(.title.weight(.bold))
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WanderCart")
    }
}

struct BrandEmptyStateLabel: View {
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(Color.brandPrimary)

            Text(title)
                .font(.title3.weight(.semibold))
        }
    }
}

extension Decimal {
    var roundedUpToWholeCoin: Decimal {
        var source = self
        var result = Decimal.zero
        NSDecimalRound(&result, &source, 0, .up)
        return result
    }

    var wanderCoinNumber: String {
        formatted(
            .number.precision(.fractionLength(0))
        )
    }

    var wanderCoinText: String {
        "\(wanderCoinNumber) W"
    }
}

private struct AppPageTitleModifier: ViewModifier {
    let title: LocalizedStringKey

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}

extension View {
    func appPageTitle(_ title: LocalizedStringKey) -> some View {
        modifier(AppPageTitleModifier(title: title))
    }

    func appPageTitle(verbatim title: String) -> some View {
        navigationTitle(title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }

    func brandPageBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(Color.brandBackground)
    }

    func brandListRow() -> some View {
        listRowBackground(Color.brandPurpleSurface)
    }
}
