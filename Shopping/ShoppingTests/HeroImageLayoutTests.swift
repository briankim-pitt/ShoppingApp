import CoreGraphics
import Testing
@testable import Shopping

struct HeroImageLayoutTests {
    private let containerWidth = 400.0
    private let containerHeight = 800.0

    @Test
    func squareImageFitsWithoutCropping() {
        let layout = HeroImageLayout.layout(
            imageSize: CGSize(width: 1000, height: 1000),
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )

        #expect(layout.height == 400)
        #expect(layout.mode == HeroImageLayout.Mode.topAlignedFill)
    }

    @Test
    func tallPortraitUsesBackdropInsteadOfStretchingPage() {
        let layout = HeroImageLayout.layout(
            imageSize: CGSize(width: 1000, height: 2000),
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )

        #expect(layout.height == 496)
        #expect(layout.mode == HeroImageLayout.Mode.fitOverBackdrop)
    }

    @Test
    func moderatelyTallImageUsesPreferredHeight() {
        let layout = HeroImageLayout.layout(
            imageSize: CGSize(width: 1000, height: 1300),
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )
        let fitHeight = 520.0

        #expect(layout.height == 496)
        #expect(layout.mode == HeroImageLayout.Mode.topAlignedFill)
        #expect(layout.height / fitHeight >= 0.9)
    }

    @Test
    func wideBannerUsesBackdropMode() {
        let layout = HeroImageLayout.layout(
            imageSize: CGSize(width: 2000, height: 500),
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )

        #expect(layout.height == 360)
        #expect(layout.mode == HeroImageLayout.Mode.fitOverBackdrop)
    }

    @Test
    func invalidImageSizeUsesPlaceholderHeight() {
        let layout = HeroImageLayout.layout(
            imageSize: .zero,
            containerWidth: containerWidth,
            containerHeight: containerHeight
        )

        #expect(abs(layout.height - 464) < 0.0001)
        #expect(layout.mode == HeroImageLayout.Mode.topAlignedFill)
    }
}
