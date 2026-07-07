import CoreGraphics

enum HeroImageLayout {
    enum Mode: Equatable {
        /// Image is at least as tall as the hero: top-anchored
        /// `scaledToFill`, cropping only the bottom (<= 10%).
        case topAlignedFill
        /// Image is shorter than the hero: `scaledToFit` pinned to the
        /// top, over a blurred copy of itself filling the remainder.
        case fitOverBackdrop
    }

    struct Layout: Equatable {
        let height: CGFloat
        let mode: Mode
    }

    /// Fraction of container height the hero prefers.
    static let preferredHeightFraction: CGFloat = 0.62
    /// Fraction of container height the hero never shrinks below (keeps
    /// room for the overlaid title block).
    static let minimumHeightFraction: CGFloat = 0.45
    /// Placeholder height fraction used before the image loads or when
    /// there is no image.
    static let placeholderHeightFraction: CGFloat = 0.58
    /// At least this fraction of the image must remain visible.
    static let minimumVisibleFraction: CGFloat = 0.9

    static func layout(
        imageSize: CGSize,
        containerWidth: CGFloat,
        containerHeight: CGFloat
    ) -> Layout {
        guard imageSize.width > 0, imageSize.height > 0, containerWidth > 0,
              containerHeight > 0
        else {
            return Layout(
                height: placeholderHeightFraction * containerHeight,
                mode: .topAlignedFill
            )
        }

        // Height the image occupies when its width fills the container.
        let fitHeight = containerWidth * imageSize.height / imageSize.width
        let preferred = preferredHeightFraction * containerHeight
        let minimum = minimumHeightFraction * containerHeight

        if fitHeight < minimum {
            // Wide image: show all of it, pad the hero with a backdrop.
            return Layout(height: minimum, mode: .fitOverBackdrop)
        }

        if fitHeight <= preferred {
            // Image fits the design band exactly; no cropping at all.
            return Layout(height: fitHeight, mode: .topAlignedFill)
        }

        let visibleFractionAtPreferredHeight = preferred / fitHeight
        if visibleFractionAtPreferredHeight >= minimumVisibleFraction {
            // Mildly tall image: preferred hero height crops at most 10%.
            return Layout(height: preferred, mode: .topAlignedFill)
        }

        // Very tall image: keep the hero stable and show the whole image
        // over a blurred backdrop instead of stretching the whole page.
        return Layout(height: preferred, mode: .fitOverBackdrop)
    }
}
