import SwiftUI
import UIKit

struct MultiTouchTapGesture: UIGestureRecognizerRepresentable {
    let action: (CGPoint) -> Void

    func makeCoordinator(
        converter: CoordinateSpaceConverter
    ) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(
        context: Context
    ) -> MultiTouchTapGestureRecognizer {
        let recognizer = MultiTouchTapGestureRecognizer()
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(
        _ recognizer: MultiTouchTapGestureRecognizer,
        context: Context
    ) {
        for globalLocation in recognizer.consumeCompletedLocations() {
            action(
                context.converter.convert(
                    globalPoint: globalLocation,
                    to: .local
                )
            )
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

final class MultiTouchTapGestureRecognizer: UIGestureRecognizer {
    private struct TouchStart {
        let location: CGPoint
        let timestamp: TimeInterval
    }

    private var starts: [ObjectIdentifier: TouchStart] = [:]
    private var movedTouches: Set<ObjectIdentifier> = []
    private var completedGlobalLocations: [CGPoint] = []

    override func touchesBegan(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        for touch in touches {
            starts[ObjectIdentifier(touch)] = TouchStart(
                location: touch.location(in: view),
                timestamp: touch.timestamp
            )
        }

        state = state == .possible ? .began : .changed
    }

    override func touchesMoved(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            guard let start = starts[id] else { continue }
            let current = touch.location(in: view)
            if hypot(
                current.x - start.location.x,
                current.y - start.location.y
            ) > 14 {
                movedTouches.insert(id)
            }
        }
    }

    override func touchesEnded(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            if let start = starts[id],
               !movedTouches.contains(id),
               touch.timestamp - start.timestamp <= 0.4 {
                completedGlobalLocations.append(touch.location(in: nil))
            }
            starts[id] = nil
            movedTouches.remove(id)
        }

        state = .changed
        if starts.isEmpty {
            state = .ended
        }
    }

    override func touchesCancelled(
        _ touches: Set<UITouch>,
        with event: UIEvent
    ) {
        for touch in touches {
            let id = ObjectIdentifier(touch)
            starts[id] = nil
            movedTouches.remove(id)
        }

        if starts.isEmpty {
            state = .cancelled
        }
    }

    override func reset() {
        starts.removeAll()
        movedTouches.removeAll()
        completedGlobalLocations.removeAll()
        super.reset()
    }

    func consumeCompletedLocations() -> [CGPoint] {
        defer { completedGlobalLocations.removeAll() }
        return completedGlobalLocations
    }
}
