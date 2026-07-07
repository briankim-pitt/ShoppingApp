import SwiftUI

/// A settings list row with a rounded icon badge, a title, and optional
/// trailing detail. Inspired by the QueueMe settings layout, restyled with
/// the WanderCart palette.
struct SettingsRow: View {
    let systemImage: String
    let iconColor: Color
    let title: String
    var detail: String?
    var showsDisclosure = false

    init(
        systemImage: String,
        iconColor: Color = .brandPrimary,
        title: String,
        detail: String? = nil,
        showsDisclosure: Bool = false
    ) {
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.title = title
        self.detail = detail
        self.showsDisclosure = showsDisclosure
    }

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(systemImage: systemImage, color: iconColor)

            Text(title)
                .fontWeight(.medium)
                .foregroundStyle(iconColor == .brandAccentCoral ? Color.brandAccentCoral : .primary)

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if showsDisclosure {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsIconBadge: View {
    let systemImage: String
    let color: Color

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 34, height: 34)
            .background(color.opacity(0.15), in: .rect(cornerRadius: 9))
            .accessibilityHidden(true)
    }
}
