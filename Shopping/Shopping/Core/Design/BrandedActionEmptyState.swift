import SwiftUI

struct BrandedActionEmptyState: View {
    let imageName: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let actionTitle: LocalizedStringKey
    let actionSystemImage: String
    let action: () -> Void

    var body: some View {
        ContentUnavailableView {
            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.brandPrimary.opacity(0.24),
                                    Color.brandPrimary.opacity(0.04),
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 64
                            )
                        )
                        .shadow(
                            color: Color.brandPrimary.opacity(0.3),
                            radius: 24
                        )

                    Image(imageName)
                        .renderingMode(.template)
                        .font(.system(size: 64, weight: .medium))
                        .foregroundStyle(Color.brandPrimary)
                }
                .frame(width: 128, height: 128)
                .accessibilityHidden(true)

                Text(title)
                    .font(.title2)
                    .bold()
            }
        } description: {
            Text(description)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        } actions: {
            Button(
                actionTitle,
                systemImage: actionSystemImage,
                action: action
            )
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(Color.brandPrimary)
        }
    }
}
