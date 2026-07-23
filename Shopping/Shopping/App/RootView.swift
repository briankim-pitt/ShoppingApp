import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ZStack {
            Color.brandBackground
                .ignoresSafeArea()

            Group {
                switch appModel.phase {
                case .launching:
                    AppLoadingIndicator(size: 36)
                case .signedOut:
                    SignInView()
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
        }
        .fontDesign(.rounded)
        .tint(Color.brandAction)
        .animation(.default, value: appModel.phase)
    }
}

#Preview("Signed Out") {
    RootView()
        .environment(PreviewData.signedOutAppModel)
}

#Preview("Ready - Light") {
    RootView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.light)
}

#Preview("Ready - Dark") {
    RootView()
        .environment(PreviewData.readyAppModel)
        .preferredColorScheme(.dark)
}
