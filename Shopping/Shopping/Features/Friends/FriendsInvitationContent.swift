import Foundation
import SwiftUI

struct FriendsInvitationContent: View {
    @Environment(\.openURL) private var openURL
    @Binding var searchText: String

    let showsFindFriendsSection: Bool

    private static let inviteURL = URL(string: "shopping://friends")!

    private let inviteMessage = "Join me on WanderCart and shop without spending."

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            inviteHeader
            shareSection

            if showsFindFriendsSection {
                findFriendsSection
            }
        }
    }

    private var inviteHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "person.2.fill")
                .font(.title)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 56, height: 56)
                .background(Color.brandPurpleSurface, in: .rect(cornerRadius: 8))
                .accessibilityHidden(true)

            Text("Bring friends along")
                .font(.largeTitle)
                .bold()

            Text("Share WanderCart, then find each other by username.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Share your invite", systemImage: "link")
                .font(.headline)
                .foregroundStyle(.secondary)

            ShareLink(
                item: Self.inviteURL,
                subject: Text("Join me on WanderCart"),
                message: Text(inviteMessage)
            ) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .accessibilityHidden(true)

                    Text("Share to Social Apps")
                        .bold()

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .accessibilityHidden(true)
                }
                .foregroundStyle(Color.brandActionForeground)
                .padding(.horizontal, 18)
                .frame(minHeight: 60)
                .background(Color.brandAction, in: .rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button(action: sendMessage) {
                inviteChannelLabel(
                    title: "Send with Messages",
                    systemImage: "message.fill",
                    tint: Color.brandSuccess
                )
            }
            .buttonStyle(.plain)

            Button(action: sendEmail) {
                inviteChannelLabel(
                    title: "Send by Email",
                    systemImage: "envelope.fill",
                    tint: Color.brandAccentCoral
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var findFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Find friends", systemImage: "magnifyingglass")
                .font(.headline)

            FriendsSearchBar(text: $searchText)

            if !trimmedSearchText.isEmpty {
                ContentUnavailableView.search
                    .frame(minHeight: 180)
            }
        }
    }

    private func inviteChannelLabel(
        title: LocalizedStringKey,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(tint, in: .rect(cornerRadius: 8))
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 68)
        .background(Color.brandPurpleSurface, in: .rect(cornerRadius: 8))
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var inviteText: String {
        "\(inviteMessage) \(Self.inviteURL.absoluteString)"
    }

    private func sendMessage() {
        openInviteURL(scheme: "sms", queryItems: [
            URLQueryItem(name: "body", value: inviteText)
        ])
    }

    private func sendEmail() {
        openInviteURL(scheme: "mailto", queryItems: [
            URLQueryItem(name: "subject", value: "Join me on WanderCart"),
            URLQueryItem(name: "body", value: inviteText)
        ])
    }

    private func openInviteURL(scheme: String, queryItems: [URLQueryItem]) {
        var components = URLComponents()
        components.scheme = scheme
        components.queryItems = queryItems

        guard let url = components.url else { return }
        openURL(url)
    }
}

#Preview {
    @Previewable @State var searchText = ""

    ScrollView {
        FriendsInvitationContent(
            searchText: $searchText,
            showsFindFriendsSection: true
        )
        .padding(20)
    }
    .brandPageBackground()
}
