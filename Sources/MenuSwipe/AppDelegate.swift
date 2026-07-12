import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let overlay = OverlayController()
    private var control: NSStatusItem!
    private var axTimer: Timer?
    private var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        control = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        control.button?.image = NSImage(systemSymbolName: "ellipsis.circle", accessibilityDescription: "MenuSwipe")
        let menu = NSMenu()
        let refresh = NSMenuItem(title: "Aggiorna icone", action: #selector(refreshNow), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        control.menu = menu

        _ = CGWindowListCreateImage(CGRect(x: 0, y: 0, width: 1, height: 1), .optionOnScreenOnly, kCGNullWindowID, [])
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)

        waitForAX()
    }

    private func waitForAX() {
        if AXIsProcessTrusted() { start(); return }
        Log.write("waiting for AX trust")
        axTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            if AXIsProcessTrusted() { t.invalidate(); self.axTimer = nil; self.start() }
        }
    }

    private func start() {
        Log.write("AX trusted — showing overlay")
        overlay.show()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.overlay.show()
        }
    }

    @objc private func refreshNow() { overlay.show() }
}
