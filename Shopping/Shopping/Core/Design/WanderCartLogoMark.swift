import SwiftUI

struct WanderCartLogoMark: View {
    var body: some View {
        WanderCartLogoShape()
            .stroke(
                Color.brandPrimary,
                style: StrokeStyle(
                    lineWidth: 6,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
            .overlay {
                GeometryReader { proxy in
                    let dotSize = proxy.size.width * 0.13

                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: proxy.size.width * 0.38,
                            y: proxy.size.height * 0.9
                        )

                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: proxy.size.width * 0.72,
                            y: proxy.size.height * 0.9
                        )
                }
            }
            .accessibilityLabel("WanderCart")
    }
}

private struct WanderCartLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.width * 0.08,
                y: rect.height * 0.12
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.23,
                y: rect.height * 0.12
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.38,
                y: rect.height * 0.68
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.53,
                y: rect.height * 0.35
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.7,
                y: rect.height * 0.68
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.91,
                y: rect.height * 0.28
            )
        )

        return path
    }
}

#Preview {
    WanderCartLogoMark()
        .frame(width: 52, height: 42)
        .padding()
}
