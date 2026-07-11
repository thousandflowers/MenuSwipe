import AppKit

/// Keeps a stable, user-defined order of apps (by bundle identifier) and exposes
/// the running apps sorted by it. New apps are appended so they get a persistent
/// slot; the user reorders via the reorder window.
struct OrderStore {

    /// Running, dock-visible apps sorted by the persisted custom order.
    func orderedRunningApps() -> [NSRunningApplication] {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }

        // Give any newly-seen app a persistent slot at the end.
        var order = Preferences.appOrder
        var changed = false
        for app in apps {
            if let id = app.bundleIdentifier, !order.contains(id) {
                order.append(id)
                changed = true
            }
        }
        if changed { Preferences.appOrder = order }

        func rank(_ app: NSRunningApplication) -> Int {
            guard let id = app.bundleIdentifier, let i = order.firstIndex(of: id) else { return .max }
            return i
        }

        return apps.sorted { a, b in
            let ra = rank(a), rb = rank(b)
            if ra != rb { return ra < rb }
            return (a.localizedName ?? "").localizedCaseInsensitiveCompare(b.localizedName ?? "") == .orderedAscending
        }
    }

    /// Persist a new order. Bundle IDs not in `ids` (apps not currently running)
    /// are kept, appended after, so they are remembered for next time.
    func setOrder(_ ids: [String]) {
        let leftover = Preferences.appOrder.filter { !ids.contains($0) }
        Preferences.appOrder = ids + leftover
    }
}
