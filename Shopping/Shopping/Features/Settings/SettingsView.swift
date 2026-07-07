import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @State private var isShowingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                accountSection
                supportSection
                appSection
                signOutSection
            }
            .brandPageBackground()
            .appPageTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
            .task {
                await appModel.loadUserEmail()
            }
            .confirmationDialog(
                "Sign out of WanderCart?",
                isPresented: $isShowingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        dismiss()
                        await appModel.signOut()
                    }
                }
            }
        }
    }

    private var accountSection: some View {
        Section("Account") {
            SettingsRow(
                systemImage: "person.crop.circle.fill",
                title: "Signed in",
                detail: appModel.userEmail ?? "—"
            )
        }
        .brandListRow()
    }

    private var supportSection: some View {
        Section("Support") {
            Button {
                contactSupport()
            } label: {
                SettingsRow(
                    systemImage: "envelope.fill",
                    title: "Contact Us",
                    showsDisclosure: true
                )
            }
        }
        .brandListRow()
    }

    private var appSection: some View {
        Section {
            Button {
                requestReview()
            } label: {
                SettingsRow(
                    systemImage: "star.fill",
                    iconColor: .yellow,
                    title: "Rate WanderCart",
                    showsDisclosure: true
                )
            }
        } header: {
            Text("App")
        } footer: {
            if let version = appVersion {
                Text("WanderCart \(version)")
            }
        }
        .brandListRow()
    }

    private var signOutSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingSignOutConfirmation = true
            } label: {
                SettingsRow(
                    systemImage: "rectangle.portrait.and.arrow.right.fill",
                    iconColor: .brandAccentCoral,
                    title: "Sign Out"
                )
            }
        }
        .brandListRow()
    }

    private var appVersion: String? {
        guard let version = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String else {
            return nil
        }

        let build = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleVersion"
        ) as? String

        return build.map { "\(version) (\($0))" } ?? version
    }

    private func contactSupport() {
        guard let url = URL(string: "mailto:support@wandercart.app") else {
            return
        }

        openURL(url)
    }
}

#Preview {
    SettingsView()
        .environment(PreviewData.readyAppModel)
}
