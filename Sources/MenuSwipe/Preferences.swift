import Foundation

/// Thin wrapper over UserDefaults for MenuSwipe's tunables.
struct Preferences {
    private static let d = UserDefaults.standard

    private enum Key {
        static let enabled = "enabled"
        static let reverse = "reverse"
        static let threshold = "threshold"
    }

    /// Whether the two-finger swipe gesture is active.
    static var enabled: Bool {
        get { d.object(forKey: Key.enabled) as? Bool ?? true }
        set { d.set(newValue, forKey: Key.enabled) }
    }

    /// Flip which swipe direction hides vs reveals.
    static var reverse: Bool {
        get { d.bool(forKey: Key.reverse) }
        set { d.set(newValue, forKey: Key.reverse) }
    }

    /// Horizontal points a swipe must cover before it toggles.
    static var threshold: Double {
        get { let v = d.double(forKey: Key.threshold); return v == 0 ? 30 : v }
        set { d.set(newValue, forKey: Key.threshold) }
    }
}
