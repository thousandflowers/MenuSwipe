import AppKit

/// Detects horizontal two-finger swipes over the menu bar using a passive
/// `NSEvent` global scroll monitor. No Accessibility/Input-Monitoring permission
/// required — the trade-off is we observe scrolls but can't consume them, which
/// is fine because the menu bar ignores scroll anyway.
final class MenuBarGestureTap {

    enum SwipeDirection {
        case left, right
        var reversed: SwipeDirection { self == .left ? .right : .left }
    }

    var horizontalThreshold: CGFloat

    private let onSwipe: (SwipeDirection) -> Void
    private var monitor: Any?

    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0
    private var didFireThisGesture = false
    private var lastEventTime: TimeInterval = 0
    private let gestureGap: TimeInterval = 0.18 // seconds of silence = new gesture

    init(threshold: CGFloat, onSwipe: @escaping (SwipeDirection) -> Void) {
        self.horizontalThreshold = threshold
        self.onSwipe = onSwipe
    }

    var isRunning: Bool { monitor != nil }

    @discardableResult
    func start() -> Bool {
        guard monitor == nil else { return true }
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handle(event)
        }
        Log.write("start() monitor installed=\(monitor != nil)")
        return monitor != nil
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        resetGesture()
    }

    private func handle(_ event: NSEvent) {
        // Two-finger trackpad scroll only (precise deltas); ignore mouse wheels.
        guard event.hasPreciseScrollingDeltas else { return }
        let hit = MenuBarGeometry.cursorIsInMenuBar()

        Log.write("scroll dx=\(String(format: "%.1f", event.scrollingDeltaX)) dy=\(String(format: "%.1f", event.scrollingDeltaY)) mouseY=\(Int(NSEvent.mouseLocation.y)) inBar=\(hit)")

        guard hit else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastEventTime > gestureGap { resetGesture() }
        lastEventTime = now

        accumulatedX += event.scrollingDeltaX
        accumulatedY += event.scrollingDeltaY
        let horizontalDominant = abs(accumulatedX) > abs(accumulatedY)

        if horizontalDominant, !didFireThisGesture, abs(accumulatedX) >= horizontalThreshold {
            didFireThisGesture = true
            let direction: SwipeDirection = accumulatedX < 0 ? .right : .left
            Log.write("FIRE \(direction) accX=\(String(format: "%.1f", accumulatedX))")
            onSwipe(direction) // global monitor already runs on the main thread
        }
    }

    private func resetGesture() {
        accumulatedX = 0
        accumulatedY = 0
        didFireThisGesture = false
    }
}
