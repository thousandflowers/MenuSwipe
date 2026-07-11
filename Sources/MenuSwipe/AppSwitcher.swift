import AppKit

/// Moves the frontmost app through the user-ordered set of running apps,
/// honouring the configured scope (all / left / right of a reference).
final class AppSwitcher {

    private let store = OrderStore()

    func switchApp(_ direction: MenuBarGestureTap.SwipeDirection) {
        let apps = store.orderedRunningApps()
        guard apps.count > 1 else { return }

        let frontPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let current = apps.firstIndex { $0.processIdentifier == frontPID } ?? 0

        let scope = scopeIndices(apps: apps, current: current)
        guard !scope.isEmpty else { return }

        let wrap = Preferences.scopeSide == .all
        guard let target = step(from: current, direction: direction, scope: scope, wrap: wrap) else { return }
        activate(apps[target])
    }

    /// The indices the swipe is allowed to land on, per side + reference.
    private func scopeIndices(apps: [NSRunningApplication], current: Int) -> [Int] {
        let n = apps.count
        let side = Preferences.scopeSide
        if side == .all { return Array(0..<n) }

        let reference: Int
        switch Preferences.scopeReference {
        case .current:
            reference = current
        case .center:
            reference = n / 2
        case .pivot:
            if let id = Preferences.pivotBundleID,
               let idx = apps.firstIndex(where: { $0.bundleIdentifier == id }) {
                reference = idx
            } else {
                reference = current // pivot not running → behave like current
            }
        }

        switch side {
        case .left:  return Array(0..<reference)
        case .right: return Array((reference + 1)..<n)
        case .all:   return Array(0..<n)
        }
    }

    /// Nearest in-scope index in the swipe direction. Wraps only when `wrap`.
    private func step(from current: Int,
                      direction: MenuBarGestureTap.SwipeDirection,
                      scope: [Int],
                      wrap: Bool) -> Int? {
        let sorted = scope.sorted()
        if direction == .right {
            if let j = sorted.first(where: { $0 > current }) { return j }
            return wrap ? sorted.first : nil
        } else {
            if let j = sorted.last(where: { $0 < current }) { return j }
            return wrap ? sorted.last : nil
        }
    }

    private func activate(_ app: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}
