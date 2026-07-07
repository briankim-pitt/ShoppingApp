import Matrix
import SwiftUI

struct AppLoadingIndicator: View {
    let title: LocalizedStringKey?
    let accessibilityTitle: LocalizedStringKey?
    let size: CGFloat

    init(
        _ title: LocalizedStringKey? = nil,
        accessibilityLabel accessibilityTitle: LocalizedStringKey? = nil,
        size: CGFloat = 28
    ) {
        self.title = title
        self.accessibilityTitle = accessibilityTitle
        self.size = size
    }

    var body: some View {
        VStack(spacing: 10) {
            Dotm3x3_3(
                size: size,
                color: Color.brandPrimary
            )
            .accessibilityHidden(true)

            if let title {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: LocalizedStringKey {
        accessibilityTitle ?? title ?? "Loading"
    }
}
