import AppKit

/// Answers "is the cursor inside the primary display's menu bar strip?".
///
/// Uses `NSEvent.mouseLocation` (AppKit global coords: origin bottom-left, y up)
/// so there is no ambiguity about which edge is the top — the menu bar sits at
/// the TOP band of the screen, the Dock at the bottom.
enum MenuBarGeometry {
    static func cursorIsInMenuBar() -> Bool {
        // screens.first owns the menu bar; its frame origin is (0,0).
        guard let screen = NSScreen.screens.first else { return false }

        let menuBarHeight = max(screen.frame.maxY - screen.visibleFrame.maxY, 24)
        let top = screen.frame.maxY                    // top edge of the screen
        let p = NSEvent.mouseLocation                  // y increases upward

        let inY = p.y <= top && p.y >= top - menuBarHeight
        let inX = p.x >= screen.frame.minX && p.x <= screen.frame.maxX
        return inY && inX
    }
}
