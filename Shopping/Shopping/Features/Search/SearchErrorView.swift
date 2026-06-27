import SwiftUI

struct SearchErrorView: View {
    let message: String

    var body: some View {
        Section {
            Label(message, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)
        }
    }
}
