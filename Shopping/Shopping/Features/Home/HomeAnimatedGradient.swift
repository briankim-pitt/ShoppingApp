import SwiftUI

struct HomeAnimatedGradient: View {
    var fadeToWhite = true

    var body: some View {
        MeshGradient(
            width: 4,
            height: 4,
            points: points,
            colors: colors,
            background: Color.brandPurpleSurface
        )
        .blur(radius: 18)
        .saturation(1.04)
        .hueRotation(.degrees(8))
        .brightness(0.09)
        .opacity(0.3)
        // A radial mask centered on the greeting turns the mesh into a soft
        // circular glow that blooms from behind the "Good ___" heading and
        // fades outward in every direction. Fading on all sides also means
        // no hard edge remains at the top when pulling to refresh, and the
        // glow dies out well above the Recently Viewed row.
        .mask {
            if fadeToWhite {
                // Centered in the frame so the glow fades symmetrically on
                // every side with margin to spare — no edge can slice through
                // it. HomeView positions the frame so this center lands on the
                // greeting.
                RadialGradient(
                    stops: [
                        .init(color: .white, location: 0.0),
                        .init(color: .white.opacity(0.82), location: 0.32),
                        .init(color: .white.opacity(0.28), location: 0.62),
                        .init(color: .clear, location: 0.96),
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 260
                )
                // Stretched into an ellipse so the glow reads wider than it
                // is tall, rather than a perfect circle.
                .scaleEffect(x: 1.6, y: 1.0)
            } else {
                Color.white
            }
        }
    }

    private var colors: [Color] {
        [
            Color(red: 0.98, green: 0.95, blue: 1.0),
            Color(red: 0.72, green: 0.48, blue: 1.0),
            Color(red: 0.58, green: 0.28, blue: 1.0),
            Color(red: 0.94, green: 0.76, blue: 1.0),
            Color(red: 0.78, green: 0.48, blue: 1.0),
            Color(red: 0.66, green: 0.42, blue: 1.0),
            Color(red: 0.7, green: 0.46, blue: 1.0),
            Color(red: 0.82, green: 0.58, blue: 1.0),
            Color(red: 0.78, green: 0.52, blue: 1.0),
            Color(red: 0.72, green: 0.48, blue: 1.0),
            Color(red: 0.82, green: 0.6, blue: 1.0),
            Color(red: 0.94, green: 0.74, blue: 1.0),
            Color(red: 0.94, green: 0.88, blue: 1.0),
            Color(red: 0.72, green: 0.48, blue: 1.0),
            Color(red: 0.86, green: 0.68, blue: 1.0),
            Color(red: 0.96, green: 0.9, blue: 1.0),
        ]
    }

    private var points: [SIMD2<Float>] {
        [
            [0.0, 0.0], [0.32, 0.0], [0.68, 0.0], [1.0, 0.0],
            [0.0, 0.24], [0.34, 0.44], [0.66, 0.42], [1.0, 0.28],
            [0.0, 0.66], [0.3, 0.72], [0.7, 0.66], [1.0, 0.7],
            [0.0, 1.0], [0.32, 1.0], [0.68, 1.0], [1.0, 1.0],
        ]
    }
}
