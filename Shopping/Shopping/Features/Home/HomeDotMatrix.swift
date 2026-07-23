import SwiftUI

struct HomeDotMatrixRipple: Identifiable {
    let id = UUID()
    let origin: CGPoint
    let startedAt: Date
}

struct HomeDotMatrix: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let ripples: [HomeDotMatrixRipple]

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / 60,
                paused: ripples.isEmpty || reduceMotion
            )
        ) { timeline in
            Canvas { context, size in
                drawRippleGlow(in: context, at: timeline.date)
                drawDots(
                    in: context,
                    size: size,
                    at: timeline.date
                )
            }
        }
        .mask {
            RadialGradient(
                stops: [
                    .init(color: .white, location: 0),
                    .init(color: .white.opacity(0.86), location: 0.58),
                    .init(color: .clear, location: 1),
                ],
                center: .center,
                startRadius: 20,
                endRadius: 245
            )
        }
        .accessibilityHidden(true)
    }

    private func drawRippleGlow(
        in context: GraphicsContext,
        at date: Date
    ) {
        guard !reduceMotion else { return }

        context.drawLayer { glowContext in
            glowContext.addFilter(.blur(radius: 6))

            for ripple in ripples {
                let elapsed = date.timeIntervalSince(ripple.startedAt)
                guard elapsed >= 0, elapsed < 1.05 else { continue }

                let progress = CGFloat(elapsed / 1.05)
                let radius = max(progress * 300, 2)
                let rect = CGRect(
                    x: ripple.origin.x - radius,
                    y: ripple.origin.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )

                glowContext.stroke(
                    Path(ellipseIn: rect),
                    with: .color(
                        Color.brandPrimary.opacity(
                            Double(1 - progress) * 0.09
                        )
                    ),
                    lineWidth: 8
                )
            }
        }
    }

    private func drawDots(
        in context: GraphicsContext,
        size: CGSize,
        at date: Date
    ) {
        let spacing: CGFloat = 18
        let columns = Int(ceil(size.width / spacing))
        let rows = Int(ceil(size.height / spacing))

        for row in 0...rows {
            for column in 0...columns {
                let center = CGPoint(
                    x: CGFloat(column) * spacing,
                    y: CGFloat(row) * spacing
                )
                let response = rippleResponse(at: center, date: date)
                let radius = 1.15 + response.strength * 2.6
                let renderedCenter = CGPoint(
                    x: center.x + response.offset.width,
                    y: center.y + response.offset.height
                )
                let rect = CGRect(
                    x: renderedCenter.x - radius,
                    y: renderedCenter.y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                let opacity = 0.12 + Double(response.strength) * 0.56

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.brandPrimary.opacity(opacity))
                )
            }
        }
    }

    private func rippleResponse(
        at point: CGPoint,
        date: Date
    ) -> (strength: CGFloat, offset: CGSize) {
        guard !reduceMotion else { return (0, .zero) }

        var strength: CGFloat = 0
        var offset = CGSize.zero

        for ripple in ripples {
            let elapsed = date.timeIntervalSince(ripple.startedAt)
            guard elapsed >= 0, elapsed < 1.05 else { continue }

            let progress = CGFloat(elapsed / 1.05)
            let deltaX = point.x - ripple.origin.x
            let deltaY = point.y - ripple.origin.y
            let distance = hypot(deltaX, deltaY)
            let waveRadius = progress * 300
            let ringDistance = abs(distance - waveRadius)
            let ringStrength = max(0, 1 - ringDistance / 34)
                * (1 - progress)

            strength = min(strength + ringStrength, 1)
            guard distance > 0 else { continue }

            offset.width += (deltaX / distance) * ringStrength * 4
            offset.height += (deltaY / distance) * ringStrength * 4
        }

        return (strength, offset)
    }
}
