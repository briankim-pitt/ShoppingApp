import SwiftUI

struct OrderBoardDotMatrix: View {
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 18
            let dotSize: CGFloat = 2
            let dot = Color.gray.opacity(0.24)

            for x in stride(from: spacing / 2, through: size.width, by: spacing) {
                for y in stride(from: spacing / 2, through: size.height, by: spacing) {
                    let rect = CGRect(
                        x: x - dotSize / 2,
                        y: y - dotSize / 2,
                        width: dotSize,
                        height: dotSize
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(dot))
                }
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
