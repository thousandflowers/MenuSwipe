import AppKit
import CoreGraphics

/// Installs a session-level scroll-event tap and reports horizontal two-finger
/// swipes that happen over the menu bar.
final class MenuBarGestureTap {

    enum SwipeDirection {
        case left, right
        var reversed: SwipeDirection { self == .left ? .right : .left }
    }

    var horizontalThreshold: CGFloat

    private let onSwipe: (SwipeDirection) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var accumulatedX: CGFloat = 0
    private var accumulatedY: CGFloat = 0
    private var didFireThisGesture = false

    init(threshold: CGFloat, onSwipe: @escaping (SwipeDirection) -> Void) {
        self.horizontalThreshold = threshold
        self.onSwipe = onSwipe
    }

    var isRunning: Bool { eventTap != nil }

    @discardableResult
    func start() -> Bool {
        guard eventTap == nil else { return true }
        Log.write("start() trusted=\(AXIsProcessTrusted())")

        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: menuSwipeTapCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            Log.write("start() tapCreate FAILED — likely missing Accessibility")
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        eventTap = tap
        runLoopSource = source
        Log.write("start() OK — tap installed")
        return true
    }

    func stop() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        eventTap = nil
        runLoopSource = nil
        resetGesture()
    }

    fileprivate func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            Log.write("tap re-enabled after \(type == .tapDisabledByTimeout ? "timeout" : "userInput")")
            if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }

        guard type == .scrollWheel else { return Unmanaged.passUnretained(event) }

        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
        let hit = MenuBarGeometry.cursorIsInMenuBar()
        let mouseY = NSEvent.mouseLocation.y
        let momentum = event.getIntegerValueField(.scrollWheelEventMomentumPhase)
        let phase = event.getIntegerValueField(.scrollWheelEventScrollPhase)
        let dx = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis2)
        let dy = event.getDoubleValueField(.scrollWheelEventFixedPtDeltaAxis1)

        Log.write("scroll cont=\(isContinuous) mouseY=\(Int(mouseY)) inBar=\(hit) phase=\(phase) mom=\(momentum) dx=\(String(format: "%.1f", dx)) dy=\(String(format: "%.1f", dy))")

        guard isContinuous, hit else { return Unmanaged.passUnretained(event) }
        if momentum != 0 { return Unmanaged.passUnretained(event) }

        if phase == 1 { resetGesture() }

        accumulatedX += CGFloat(dx)
        accumulatedY += CGFloat(dy)
        let horizontalDominant = abs(accumulatedX) > abs(accumulatedY)

        if horizontalDominant, !didFireThisGesture, abs(accumulatedX) >= horizontalThreshold {
            didFireThisGesture = true
            let direction: SwipeDirection = accumulatedX < 0 ? .right : .left
            Log.write("FIRE \(direction) (accX=\(String(format: "%.1f", accumulatedX)))")
            DispatchQueue.main.async { self.onSwipe(direction) }
        }

        if phase == 4 || phase == 8 { resetGesture() }

        return horizontalDominant ? nil : Unmanaged.passUnretained(event)
    }

    private func resetGesture() {
        accumulatedX = 0
        accumulatedY = 0
        didFireThisGesture = false
    }
}

private func menuSwipeTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<MenuBarGestureTap>.fromOpaque(refcon).takeUnretainedValue()
    return tap.handle(type, event)
}
