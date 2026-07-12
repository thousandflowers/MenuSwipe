import AppKit
import ApplicationServices

/// One enumerated menu bar extra: the AX element (to press), its real screen
/// frame (to capture its glyph), and an app-icon fallback.
struct MenuBarItem {
    let element: AXUIElement
    let appName: String
    let frame: CGRect          // screen coords, top-left origin
    let fallbackIcon: NSImage?
}

enum AXMenuBar {
    static func items() -> [MenuBarItem] {
        let screen = NSScreen.main
        let menuBarH = screen.map { max($0.frame.maxY - $0.visibleFrame.maxY, 24) } ?? 24
        let screenW = screen?.frame.width ?? 5000

        var result: [MenuBarItem] = []
        for app in NSWorkspace.shared.runningApplications where app.processIdentifier > 0 {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var extras: CFTypeRef?
            guard AXUIElementCopyAttributeValue(axApp, "AXExtrasMenuBar" as CFString, &extras) == .success,
                  let ex = extras, CFGetTypeID(ex) == AXUIElementGetTypeID() else { continue }

            var childrenVal: CFTypeRef?
            AXUIElementCopyAttributeValue(ex as! AXUIElement, kAXChildrenAttribute as CFString, &childrenVal)
            guard let kids = childrenVal as? [AXUIElement] else { continue }

            let icon = app.icon
            let name = app.localizedName ?? "?"
            for kid in kids {
                let frame = frameOf(kid, menuBarHeight: menuBarH)
                guard frame.minX.isFinite, frame.minY.isFinite else { continue }
                _ = screenW
                result.append(MenuBarItem(element: kid, appName: name, frame: frame, fallbackIcon: icon))
            }
        }
        return result.sorted { $0.frame.minX < $1.frame.minX }
    }

    private static func frameOf(_ el: AXUIElement, menuBarHeight: CGFloat) -> CGRect {
        var posVal: CFTypeRef?
        var sizeVal: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXPositionAttribute as CFString, &posVal)
        AXUIElementCopyAttributeValue(el, kAXSizeAttribute as CFString, &sizeVal)
        var p = CGPoint.zero
        var s = CGSize.zero
        if let posVal, CFGetTypeID(posVal) == AXValueGetTypeID() { AXValueGetValue(posVal as! AXValue, .cgPoint, &p) }
        if let sizeVal, CFGetTypeID(sizeVal) == AXValueGetTypeID() { AXValueGetValue(sizeVal as! AXValue, .cgSize, &s) }
        let w = s.width  > 2 ? s.width  : 24
        let h = s.height > 2 ? s.height : menuBarHeight
        return CGRect(x: p.x, y: p.y, width: w, height: h)
    }

    static func press(_ item: MenuBarItem) {
        AXUIElementPerformAction(item.element, kAXPressAction as CFString)
    }

    /// Capture the real glyph pixels at `frame`, excluding our overlay window so
    /// we image the true menu bar underneath (needs Screen Recording).
    static func captureGlyph(_ frame: CGRect, belowWindow number: Int) -> NSImage? {
        guard let cg = CGWindowListCreateImage(frame, .optionOnScreenBelowWindow, CGWindowID(number), .bestResolution),
              cg.width > 0 else { return nil }
        return NSImage(cgImage: cg, size: frame.size)
    }
}
