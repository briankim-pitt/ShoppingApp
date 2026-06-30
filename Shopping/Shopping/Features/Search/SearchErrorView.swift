import SwiftUI

struct SearchErrorView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(Color.brandAccentCoral)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                Color.brandAccentCoral.opacity(0.08),
                in: .rect(cornerRadius: 14)
            )
    }
}
