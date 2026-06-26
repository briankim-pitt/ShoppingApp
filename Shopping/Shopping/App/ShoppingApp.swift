import SwiftUI

@main
struct ShoppingApp: App {
    @State private var appModel = AppModel.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appModel)
                .task {
                    await appModel.start()
                }
        }
    }
}
