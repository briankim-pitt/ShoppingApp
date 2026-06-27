import SwiftUI

private struct AppPageTitleModifier: ViewModifier {
    let title: LocalizedStringKey

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inlineLarge)
    }
}

extension View {
    func appPageTitle(_ title: LocalizedStringKey) -> some View {
        modifier(AppPageTitleModifier(title: title))
    }
}
