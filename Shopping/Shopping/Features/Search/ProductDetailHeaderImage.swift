import SwiftUI

struct ProductDetailHeaderImage: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url?.upgradingToHTTPS) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            case .failure:
                placeholder(systemImage: "bag")
            case .empty:
                placeholder(systemImage: nil)
            @unknown default:
                placeholder(systemImage: nil)
            }
        }
        .overlay(alignment: .bottom) {
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.14),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 96)
        }
        .clipped()
    }

    private func placeholder(systemImage: String?) -> some View {
        Color(uiColor: .systemGroupedBackground)
            .overlay {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .tint(Color.brandPrimary)
                }
            }
    }
}
