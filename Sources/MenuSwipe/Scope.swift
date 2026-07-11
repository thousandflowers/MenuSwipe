import Foundation

/// Which side of the reference the swipe is allowed to roam.
enum ScopeSide: String, CaseIterable {
    case all    // whole ring, wraps
    case left   // only apps before the reference
    case right  // only apps after the reference
}

/// What the "left / right" is measured against.
enum ScopeReference: String, CaseIterable {
    case current // the app currently in front (dynamic)
    case pivot   // a fixed app the user picks
    case center  // the middle of the ordered list
}
