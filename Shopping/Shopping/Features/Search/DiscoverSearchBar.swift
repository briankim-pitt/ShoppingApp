import SwiftUI

struct DiscoverSearchBar: View {
    @Binding var text: String
    let mode: SearchMode
    let submit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: mode == .products ? "magnifyingglass" : "link")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            TextField(prompt, text: $text)
                .textInputAutocapitalization(.never)
                .keyboardType(mode == .products ? .default : .URL)
                .textContentType(mode == .products ? nil : .URL)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(submit)

            if !text.isEmpty {
                Button(
                    "Clear Search",
                    systemImage: "xmark.circle.fill",
                    action: clear
                )
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .glassEffect(.regular.interactive())
    }

    private var prompt: String {
        switch mode {
        case .products:
            "Search items, brands, categories…"
        case .url:
            "Paste a product URL…"
        }
    }

    private func clear() {
        text = ""
    }
}
