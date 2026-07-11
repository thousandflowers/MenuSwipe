import Foundation

/// Thin wrapper over UserDefaults for the tunables MenuSwipe exposes.
struct Preferences {
    private static let d = UserDefaults.standard

    private enum Key {
        static let enabled = "enabled"
        static let reverse = "reverse"
        static let threshold = "threshold"
        static let appOrder = "appOrder"
        static let scopeSide = "scopeSide"
        static let scopeReference = "scopeReference"
        static let pivotBundleID = "pivotBundleID"
    }

    static var enabled: Bool {
        get { d.object(forKey: Key.enabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.enabled) }
    }

    static var reverse: Bool {
        get { d.bool(forKey: Key.reverse) }
        set { d.set(newValue, forKey: Key.reverse) }
    }

    /// Horizontal points a swipe must cover before it counts as one app switch.
    static var threshold: Double {
        get { let v = d.double(forKey: Key.threshold); return v == 0 ? 40 : v }
        set { d.set(newValue, forKey: Key.threshold) }
    }

    /// Persisted custom app order, as bundle identifiers.
    static var appOrder: [String] {
        get { d.stringArray(forKey: Key.appOrder) ?? [] }
        set { d.set(newValue, forKey: Key.appOrder) }
    }

    static var scopeSide: ScopeSide {
        get { ScopeSide(rawValue: d.string(forKey: Key.scopeSide) ?? "") ?? .all }
        set { d.set(newValue.rawValue, forKey: Key.scopeSide) }
    }

    static var scopeReference: ScopeReference {
        get { ScopeReference(rawValue: d.string(forKey: Key.scopeReference) ?? "") ?? .current }
        set { d.set(newValue.rawValue, forKey: Key.scopeReference) }
    }

    static var pivotBundleID: String? {
        get { d.string(forKey: Key.pivotBundleID) }
        set { d.set(newValue, forKey: Key.pivotBundleID) }
    }
}
