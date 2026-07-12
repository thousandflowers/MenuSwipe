import AppKit

/// Borderless overlay over the menu bar icon area. Does NOT consume bar width
/// (unlike a status item), so it never pushes real icons behind the notch. Each
/// tile is the captured glyph of a real status item (incl. bar background), laid
/// edge-to-edge and scrollable; clicking AXPresses the real element in place.
final class OverlayController {

    private var window: NSWindow?
    private var scroll: NSScrollView!
    private var doc: NSView!
    private var items: [MenuBarItem] = []

    private let width: CGFloat = 360
    private let rightInset: CGFloat = 200   // keep clock + Control Center clear

    func show() {
        buildIfNeeded()
        reload()
        window?.orderFrontRegardless()
    }

    private func buildIfNeeded() {
        guard window == nil, let screen = NSScreen.main else { return }
        let menuBarH = max(screen.frame.maxY - screen.visibleFrame.maxY, 24)
        let x = screen.frame.maxX - rightInset - width
        let y = screen.frame.maxY - menuBarH
        let frame = NSRect(x: x, y: y, width: width, height: menuBarH)

        let w = NSWindow(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        w.isOpaque = false
        w.backgroundColor = .clear
        w.hasShadow = false
        w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 1)
        w.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]

        let sv = NSScrollView(frame: w.contentView!.bounds)
        sv.autoresizingMask = [.width, .height]
        sv.drawsBackground = false
        sv.hasHorizontalScroller = false
        sv.hasVerticalScroller = false
        sv.horizontalScrollElasticity = .allowed
        sv.verticalScrollElasticity = .none
        let d = NSView()
        sv.documentView = d
        w.contentView!.addSubview(sv)

        window = w; scroll = sv; doc = d
    }

    func reload() {
        guard let doc, let scroll, let window else { return }
        items = AXMenuBar.items()
        doc.subviews.forEach { $0.removeFromSuperview() }

        let h = window.frame.height
        let winNumber = window.windowNumber
        var captured = 0
        var x: CGFloat = 0
        for (i, item) in items.enumerated() {
            let tileW = min(max(item.frame.width, 22), 44)
            let glyph = AXMenuBar.captureGlyph(item.frame, belowWindow: winNumber)
            if glyph != nil { captured += 1 }

            let b = NSButton(frame: NSRect(x: x, y: 0, width: tileW, height: h))
            b.isBordered = false
            b.bezelStyle = .regularSquare
            b.imageScaling = glyph != nil ? .scaleProportionallyUpOrDown : .scaleProportionallyDown
            b.image = glyph ?? item.fallbackIcon
            b.toolTip = item.appName
            b.tag = i
            b.target = self
            b.action = #selector(clicked(_:))
            doc.addSubview(b)
            x += tileW
        }
        doc.frame = NSRect(x: 0, y: 0, width: max(x, scroll.bounds.width), height: h)
        Log.write("overlay: \(items.count) items, \(captured) glyphs, contentW=\(Int(x))")
    }

    @objc private func clicked(_ sender: NSButton) {
        guard sender.tag < items.count else { return }
        AXMenuBar.press(items[sender.tag])
    }
}
