import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let switcher = AppSwitcher()
    private let reorderController = ReorderWindowController()
    private var tap: MenuBarGestureTap!
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        tap = MenuBarGestureTap(threshold: CGFloat(Preferences.threshold)) { [weak self] direction in
            guard let self, Preferences.enabled else { return }
            let effective = Preferences.reverse ? direction.reversed : direction
            self.switcher.switchApp(effective)
        }

        setupStatusItem()
        requestAccessibility()
        applyEnabledState()
    }

    // MARK: - Status item / menu

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "arrow.left.arrow.right",
                                   accessibilityDescription: "MenuSwipe")
        }
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let header = NSMenuItem(title: "MenuSwipe", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        addCheck(menu, "Attivo", #selector(toggleEnabled), on: Preferences.enabled)
        addCheck(menu, "Inverti direzione", #selector(toggleReverse), on: Preferences.reverse)

        menu.addItem(sensitivitySubmenu())
        menu.addItem(scopeSubmenu())

        menu.addItem(.separator())

        let reorder = NSMenuItem(title: "Riordina app…", action: #selector(openReorder), keyEquivalent: "")
        reorder.target = self
        menu.addItem(reorder)

        let perm = NSMenuItem(title: "Concedi accessibilità…", action: #selector(openAccessibility), keyEquivalent: "")
        perm.target = self
        menu.addItem(perm)

        menu.addItem(NSMenuItem(title: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func addCheck(_ menu: NSMenu, _ title: String, _ action: Selector, on: Bool) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.state = on ? .on : .off
        item.target = self
        menu.addItem(item)
    }

    private func sensitivitySubmenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Sensibilità", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for (title, value) in [("Bassa", 70.0), ("Media", 40.0), ("Alta", 20.0)] {
            let item = NSMenuItem(title: title, action: #selector(setSensitivity(_:)), keyEquivalent: "")
            item.representedObject = value
            item.state = Preferences.threshold == value ? .on : .off
            item.target = self
            sub.addItem(item)
        }
        root.submenu = sub
        return root
    }

    private func scopeSubmenu() -> NSMenuItem {
        let root = NSMenuItem(title: "Ambito swipe", action: nil, keyEquivalent: "")
        let sub = NSMenu()

        let dirHeader = NSMenuItem(title: "Quali app scorrere", action: nil, keyEquivalent: "")
        dirHeader.isEnabled = false
        sub.addItem(dirHeader)
        for (title, side) in [("Tutte", ScopeSide.all), ("Solo a sinistra", .left), ("Solo a destra", .right)] {
            let item = NSMenuItem(title: title, action: #selector(setSide(_:)), keyEquivalent: "")
            item.representedObject = side.rawValue
            item.state = Preferences.scopeSide == side ? .on : .off
            item.target = self
            sub.addItem(item)
        }

        sub.addItem(.separator())

        let refHeader = NSMenuItem(title: "Sinistra/destra rispetto a", action: nil, keyEquivalent: "")
        refHeader.isEnabled = false
        sub.addItem(refHeader)
        for (title, ref) in [("App attiva", ScopeReference.current), ("App fissa…", .pivot), ("Metà lista", .center)] {
            let item = NSMenuItem(title: title, action: #selector(setReference(_:)), keyEquivalent: "")
            item.representedObject = ref.rawValue
            item.state = Preferences.scopeReference == ref ? .on : .off
            item.target = self
            if ref == .pivot { item.submenu = pivotSubmenu() }
            sub.addItem(item)
        }

        root.submenu = sub
        return root
    }

    private func pivotSubmenu() -> NSMenu {
        let menu = NSMenu()
        for app in OrderStore().orderedRunningApps() {
            guard let id = app.bundleIdentifier else { continue }
            let item = NSMenuItem(title: app.localizedName ?? id, action: #selector(setPivot(_:)), keyEquivalent: "")
            item.representedObject = id
            item.state = Preferences.pivotBundleID == id ? .on : .off
            item.target = self
            menu.addItem(item)
        }
        return menu
    }

    // MARK: - Actions

    @objc private func toggleEnabled() {
        Preferences.enabled.toggle()
        applyEnabledState()
        rebuildMenu()
    }

    @objc private func toggleReverse() {
        Preferences.reverse.toggle()
        rebuildMenu()
    }

    @objc private func setSensitivity(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        Preferences.threshold = value
        tap.horizontalThreshold = CGFloat(value)
        rebuildMenu()
    }

    @objc private func setSide(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let side = ScopeSide(rawValue: raw) {
            Preferences.scopeSide = side
        }
        rebuildMenu()
    }

    @objc private func setReference(_ sender: NSMenuItem) {
        if let raw = sender.representedObject as? String, let ref = ScopeReference(rawValue: raw) {
            Preferences.scopeReference = ref
        }
        rebuildMenu()
    }

    @objc private func setPivot(_ sender: NSMenuItem) {
        if let id = sender.representedObject as? String {
            Preferences.pivotBundleID = id
            Preferences.scopeReference = .pivot
        }
        rebuildMenu()
    }

    @objc private func openReorder() {
        reorderController.show()
    }

    @objc private func openAccessibility() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    // MARK: - Tap lifecycle / permission

    private func applyEnabledState() {
        guard Preferences.enabled else {
            tap.stop()
            updateStatusAppearance()
            return
        }
        if !tap.start() { startPermissionPolling() }
        updateStatusAppearance()
    }

    private func requestAccessibility() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Retry starting the tap until the user grants Accessibility.
    private func startPermissionPolling() {
        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            if !Preferences.enabled { timer.invalidate(); return }
            if self.tap.start() {
                timer.invalidate()
                self.permissionTimer = nil
                self.updateStatusAppearance()
            }
        }
    }

    private func updateStatusAppearance() {
        let active = Preferences.enabled && tap.isRunning
        statusItem.button?.appearsDisabled = !active
        statusItem.button?.toolTip = active
            ? "MenuSwipe attivo — swipe a due dita sulla menu bar"
            : "MenuSwipe in pausa (attiva o concedi accessibilità)"
    }
}
