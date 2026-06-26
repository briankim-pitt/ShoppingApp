import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            switch appModel.phase {
            case .launching:
                ProgressView()
                    .controlSize(.large)
            case .signedOut:
                SignInView()
            case .needsCurrency:
                CurrencySelectionView()
            case .ready:
                MainTabView()
            case .configurationError(let message):
                ContentUnavailableView {
                    Label("Configuration Needed", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text(message)
                }
            }
        }
        .animation(.default, value: appModel.phase)
    }
}

#Preview("Signed Out") {
    RootView()
        .environment(PreviewData.signedOutAppModel)
}

#Preview("Currency Onboarding") {
    RootView()
        .environment(PreviewData.onboardingAppModel)
}

#Preview("Ready") {
    RootView()
        .environment(PreviewData.readyAppModel)
}
