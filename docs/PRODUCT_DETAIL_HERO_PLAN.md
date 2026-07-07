# Execution Plan: App Store–Style Product Detail Hero

Goal: rework the product detail hero to match the App Store "story" card
look:

1. A **true progressive blur** at the bottom of the image (sharp at top,
   increasingly blurred toward the bottom) with the title block overlaid.
2. The image **fills edge to edge** horizontally.
3. Sizing rule: **at least 90% of the image is always visible, anchored to
   the top** — for clothing photos the model's head must never be cropped.
   Cropping, when needed, happens only at the bottom and never exceeds 10%.

This plan is prescriptive: follow phases in order, read every file in each
"Read first" list before editing, match surrounding style, and run the
verification steps as written.

## Ground rules

- iOS 26+, Swift 6 strict concurrency, SwiftUI. Run the `swiftui-pro`
  skill review over changed SwiftUI files before finishing.
- The app is currently locked to light mode via `.preferredColorScheme(.light)`
  in `App/ShoppingApp.swift` — hero overlay text must be explicitly white
  (it sits on an image), never `.primary`.
- No backend, model, or service changes. UI only.
- Do not change `ProductPurchaseGlassBar`, the wishlist logic, or the
  "About this product" section in `ProductDetailView` (the hero subtitle
  duplicates the first lines of the description on purpose, like the App
  Store card does).

---

## Phase 1 — Add the variable blur component

**Read first:** `QueueMe/QueueMe/VariableBlur.swift` (source to copy),
`Shopping/Shopping/Core/Design/` (destination conventions).

Copy `QueueMe/QueueMe/VariableBlur.swift` into
`Shopping/Shopping/Core/Design/VariableBlur.swift` with these edits:

- Replace the Xcode file header with a one-line comment crediting
  `https://github.com/jtrivedi/VariableBlurView` (keep the existing credit
  line inside the class too).
- Remove the `public` access modifiers (everything else in this app is
  internal).
- Keep everything else byte-identical — including the odd-looking
  reversed-string lookups and the empty `traitCollectionDidChange`
  override; they are deliberate (see the comments in the file).

**Known trade-off, do not "fix":** this view drives a private Core
Animation filter through KVC. It ships in the sibling QueueMe app and
renders the exact App Store effect. If it ever breaks on a future OS, the
view degrades to a plain `UIVisualEffectView`; no crash path exists besides
the guarded lookups.

Do not modify the QueueMe copy.

**Verify:** project still builds
(`xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping
-destination 'generic/platform=iOS Simulator' build -quiet`).

---

## Phase 2 — Hero sizing math (pure + unit-tested)

**Read first:** `Shopping/ShoppingTests/OrderListFilterTests.swift`
(Swift Testing style).

New file `Shopping/Shopping/Features/Search/HeroImageLayout.swift`:

```swift
import CoreGraphics

enum HeroImageLayout {
    enum Mode: Equatable {
        /// Image is at least as tall as the hero: top-anchored
        /// `scaledToFill`, cropping only the bottom (≤ 10%).
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

        // Tall image: cap at the preferred height, but never crop more
        // than (1 - minimumVisibleFraction) of the image. The 90% rule
        // wins over the design cap.
        let height = max(preferred, minimumVisibleFraction * fitHeight)
        return Layout(height: height, mode: .topAlignedFill)
    }
}
```

New test file `Shopping/ShoppingTests/HeroImageLayoutTests.swift`
(Swift Testing: `import Testing`, `@testable import Shopping`, struct +
`@Test` + `#expect`). Use `containerWidth: 400, containerHeight: 800`
throughout. Cases:

1. Square image (1000×1000): `fitHeight` 400 < preferred 496 →
   height == 400, mode `.topAlignedFill` (no crop).
2. Tall portrait (1000×2000): `fitHeight` 800 → height ==
   `max(496, 720)` == 720, mode `.topAlignedFill`; assert
   `height / fitHeight >= 0.9` (the 90% rule).
3. Moderately tall (1000×1300): `fitHeight` 520 → height ==
   `max(496, 468)` == 496; visible fraction 496/520 ≈ 0.954 ≥ 0.9.
4. Wide banner (2000×500): `fitHeight` 100 < minimum 360 → height == 360,
   mode `.fitOverBackdrop`.
5. Zero/invalid image size → placeholder height `0.58 * 800` and
   `.topAlignedFill`.

**Verify:** full suite green:
`xcodebuild -project Shopping/Shopping.xcodeproj -scheme Shopping
-destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -quiet`.

---

## Phase 3 — Rebuild `ProductDetailHeroImage`

**Read first:** `Features/Search/ProductDetailHeroImage.swift` (current
implementation being replaced), `Features/Search/ProductDetailView.swift`,
`Core/Extensions/URL+ProductImport.swift` (for `upgradingToHTTPS`),
`Core/Design/AppPageTitleModifier.swift` (brand colors).

Rewrite `ProductDetailHeroImage.swift`. Key differences from today:

- The current version center-crops (`scaledToFill` in a fixed 58% frame),
  which is what decapitates portrait photos — replace with the Phase 2
  layout. It also fakes the blur with a second blurred copy of the image
  that doesn't align with the layer beneath; the `VariableBlurView`
  replaces that entirely (a backdrop filter always matches what's behind
  it by construction).
- `AsyncImage` cannot report the image's pixel size, which the layout
  math needs. Load with `URLSession` instead.

### 3a. Signature and state

```swift
struct ProductDetailHeroImage: View {
    let url: URL?
    let title: String
    let eyebrow: String      // brand ?? sourceDomain (caller decides)
    let subtitle: String?    // first lines of description, optional

    @State private var loadedImage: UIImage?
    @State private var didFail = false
}
```

Call site in `ProductDetailView`:

```swift
ProductDetailHeroImage(
    url: product.imageURL,
    title: product.title,
    eyebrow: (product.brand ?? product.sourceDomain).uppercased(),
    subtitle: product.description
)
```

Everything else in `ProductDetailView.body` stays as is (it already does
`ignoresSafeArea(edges: .top)` + hidden toolbar background, which gives
the edge-to-edge top).

### 3b. Image loading

`.task(id: url)` on the hero: if `url == nil` set `didFail = true`;
otherwise `URLSession.shared.data(from: url.upgradingToHTTPS)` →
`UIImage(data:)`. On any error or nil image set `didFail = true`. Wrap
assignment in `withAnimation(.snappy)` so the height change from
placeholder → measured is animated, not a jump. (URLSession's shared
`URLCache` makes repeat visits instant; do not add a custom cache.)

### 3c. Layout

Use `GeometryReader`-free sizing: keep the existing
`containerRelativeFrame(.vertical)` + `containerRelativeFrame(.horizontal)`
pattern to obtain lengths. Simplest correct structure:

```swift
var body: some View {
    heroContent
        .containerRelativeFrame([.horizontal, .vertical]) { length, axis in
            // Capture both lengths into @State via onChange? NO — instead:
        }
}
```

That pattern gets awkward for two axes, so do this instead: wrap the hero
in a plain `Color.clear.frame(height: heroHeight)` where `heroHeight` is
computed from `UIScreen`-independent geometry via `onGeometryChange`:

```swift
@State private var containerSize: CGSize = .zero

var body: some View {
    ZStack(alignment: .top) { ... layers ... }
        .frame(height: layout.height)
        .frame(maxWidth: .infinity)
        .clipped()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { containerSize = $0 }
        ...
}
```

Careful: `onGeometryChange` reports the hero's own size; for
`containerHeight` you need the *screen-ish* container, so attach the
geometry read to the outer `ScrollView` content? Do NOT overthink this:
read the width from `onGeometryChange` on the hero (its width is the
screen width because it is `maxWidth: .infinity` inside an edge-to-edge
scroll view), and take the height from
`containerRelativeFrame(.vertical)` on a background `Color.clear`:

```swift
.background {
    Color.clear.containerRelativeFrame(.vertical) { length, _ in
        Task { @MainActor in containerHeight = length }  // NO — side effects in the closure are forbidden
        return length
    }
}
```

Side effects there are not allowed, so use the simplest legal source for
the container height: `@Environment(\.self)`-free `UIScreen` is
deprecated territory; instead pass the height *in* from
`ProductDetailView`, which already lives in a `ScrollView`:

```swift
// ProductDetailView
ScrollView { ... }
    .onGeometryChange(for: CGSize.self) { $0.size } action: { scrollSize = $0 }
// pass scrollSize into ProductDetailHeroImage as `containerSize`
```

This is the decided approach — `ProductDetailView` owns
`@State private var containerSize: CGSize = .zero`, measures the
`ScrollView` with `onGeometryChange`, and hands it to the hero. The hero
then computes:

```swift
private var layout: HeroImageLayout.Layout {
    HeroImageLayout.layout(
        imageSize: loadedImage?.size ?? .zero,
        containerWidth: containerSize.width,
        containerHeight: containerSize.height
    )
}
```

Guard: while `containerSize == .zero`, render the placeholder at a fixed
360-point height to avoid a zero-height flash on first layout pass.

### 3d. Layer stack (bottom to top), inside the clipped, height-fixed frame

1. **Backdrop** (only when `layout.mode == .fitOverBackdrop`): the loaded
   image, `resizable().scaledToFill()`, `blur(radius: 40)`, `.clipped()`,
   filling the hero.
2. **Image**:
   - `.topAlignedFill`: `Image(uiImage:).resizable().scaledToFill()`
     inside `.frame(width: containerSize.width, height: layout.height,
     alignment: .top)` then `.clipped()` — top-anchored, so only the
     bottom crops.
   - `.fitOverBackdrop`: `resizable().scaledToFit()` with
     `.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)`.
3. **Progressive blur**: `VariableBlurView(maxBlurRadius: 8, direction:
   .blurredBottomClearTop, startOffset: -0.1)` in a bottom-aligned frame
   `height: layout.height * 0.5`, `.frame(maxHeight: .infinity,
   alignment: .bottom)`. Tune radius 6–10 by eye in the preview; the App
   Store effect is subtle.
4. **Scrim** for text contrast (lighter than the current one — the blur
   now does most of the legibility work):
   `LinearGradient(colors: [.clear, .black.opacity(0.25),
   .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)` bottom
   half only, same frame trick as the blur.
5. **Text block**, bottom-leading, `padding(.horizontal, 24)`,
   `padding(.bottom, 28)`:
   - eyebrow: `.font(.footnote.weight(.semibold))`,
     `.foregroundStyle(.white.opacity(0.7))`, `lineLimit(1)`
   - title: `.font(.largeTitle.weight(.bold))`,
     `.foregroundStyle(.white)`, `lineLimit(3)`,
     `.minimumScaleFactor(0.82)`
   - subtitle (if non-nil, non-empty): `.font(.subheadline)`,
     `.foregroundStyle(.white.opacity(0.75))`, `lineLimit(2)`

### 3e. States

- **Loading** (`loadedImage == nil && !didFail`): brand-surface rectangle
  (`Color.brandPurpleSurface`) at placeholder height with a centered
  `ProgressView().tint(Color.brandPrimary)`; still render the text block
  and scrim so the title never pops in late.
- **Failed / no URL**: same placeholder with
  `Image(systemName: "bag")` centered, text block still overlaid on the
  scrim.

### 3f. Accessibility

The current file hides the whole hero (`accessibilityHidden(true)`),
which also hides the title — a real bug. New behavior: hide the image
and blur layers individually (`.accessibilityHidden(true)`), keep the
text block visible, and group it:
`.accessibilityElement(children: .combine)`. Remove the blanket modifier.

### 3g. Preview

Update the `#Preview` to show two variants: `PreviewData.product`
(landscape-ish) and one hand-built `Product` with a portrait `imageURL`
(any tall Unsplash URL) to exercise the 90% rule visually.

**Verify:** build + full test suite (commands above, zero new warnings),
then swiftui-pro review over `ProductDetailHeroImage.swift`,
`ProductDetailView.swift`, `HeroImageLayout.swift`.

---

## Phase 4 — Manual QA notes (device or simulator)

- Portrait clothing product: head visible, crop only at the hem, blur
  ramps smoothly with no hard line where the blur region starts.
- Wide banner product: full image visible, blurred backdrop fills the
  hero band, no letterbox bars.
- No-image product: placeholder + readable title block.
- Scroll: text block scrolls away with the image (no pinning); status
  bar/back button remain legible (toolbar background already hidden —
  unchanged).

## Completion checklist

- [ ] `VariableBlur.swift` copied to `Core/Design/`, internal access,
      QueueMe original untouched.
- [ ] `HeroImageLayout` pure math + 5 unit tests green; 90% rule asserted.
- [ ] Hero: edge-to-edge, top-anchored, ≤10% bottom crop, real
      progressive blur, eyebrow/title/subtitle overlay in fixed white.
- [ ] Accessibility: title block readable by VoiceOver, image hidden.
- [ ] Loading/failure states keep the text overlay.
- [ ] Build clean, full suite green, swiftui-pro review done.
