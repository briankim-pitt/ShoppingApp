import SwiftUI

struct MainTabLabel: View {
    let tab: MainTab
    let isSelected: Bool

    var body: some View {
        Image(tab.iconName(isSelected: isSelected))
            .renderingMode(.template)
            .environment(\.symbolVariants, .none)
            .accessibilityLabel(tab.title)
    }
}
