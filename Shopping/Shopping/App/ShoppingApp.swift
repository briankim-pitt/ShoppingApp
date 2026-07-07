import SwiftUI
import UIKit

@main
struct ShoppingApp: App {
    @State private var appModel = AppModel.live()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.largeTitleTextAttributes = [
            .font: Self.roundedSystemFont(size: 34, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .font: Self.roundedSystemFont(size: 17, weight: .semibold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                // Locked to light mode for now. The dark-mode color logic is
                // preserved; remove this modifier to re-enable system theming.
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    appModel.handleIncomingURL(url)
                }
                .task {
                    await appModel.start()
            }
        }
    }

    private static func roundedSystemFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = font.fontDescriptor.withDesign(.rounded) else {
            return font
        }

        return UIFont(descriptor: descriptor, size: size)
    }
}
