import AppKit

/// Hides/reveals the menu bar icons the user has Cmd-dragged to the LEFT of the
/// boundary item. Mechanism (no permission needed, à la Hidden Bar / Dozer):
/// expanding a status item's width shoves the items on its left past the screen
/// edge, hiding them. Collapsing it back brings them into view.
final class MenuBarHider {

    private let boundary: NSStatusItem
    private let control: NSStatusItem

    private let shownWidth: CGFloat = 8
    private let hiddenWidth: CGFloat = 10_000

    private(set) var isCollapsed = false

    init() {
        // Boundary marker (the "│"): the divider you drag hideable icons to the left of.
        boundary = NSStatusBar.system.statusItem(withLength: shownWidth)
        boundary.button?.title = "│"

        // Always-visible control on the right, carries the app menu.
        control = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        apply()
    }

    /// The always-visible item; attach the settings menu here.
    var controlItem: NSStatusItem { control }

    func toggle()   { setCollapsed(!isCollapsed) }
    func collapse() { setCollapsed(true) }
    func expand()   { setCollapsed(false) }

    func setCollapsed(_ collapsed: Bool) {
        guard collapsed != isCollapsed else { return }
        isCollapsed = collapsed
        apply()
    }

    private func apply() {
        boundary.length = isCollapsed ? hiddenWidth : shownWidth
        control.button?.image = NSImage(
            systemSymbolName: isCollapsed ? "chevron.right" : "chevron.left",
            accessibilityDescription: "MenuSwipe")
    }
}
