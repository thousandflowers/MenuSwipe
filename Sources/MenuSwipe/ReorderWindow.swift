import AppKit
import SwiftUI

/// Owns the single reorder window and shows it on demand.
final class ReorderWindowController {
    private var window: NSWindow?

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: ReorderView())
        let w = NSWindow(contentViewController: hosting)
        w.title = "Ordine app — MenuSwipe"
        w.styleMask = [.titled, .closable]
        w.setContentSize(NSSize(width: 320, height: 440))
        w.isReleasedWhenClosed = false
        w.center()
        window = w

        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct AppRow: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
}

private struct ReorderView: View {
    @State private var rows: [AppRow] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Trascina per riordinare. Lo swipe scorre le app in quest'ordine.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)

            List {
                ForEach(rows) { row in
                    HStack(spacing: 8) {
                        if let icon = row.icon {
                            Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                        }
                        Text(row.name)
                    }
                }
                .onMove(perform: move)
            }
        }
        .frame(minWidth: 300, minHeight: 400)
        .onAppear(perform: reload)
    }

    private func reload() {
        rows = OrderStore().orderedRunningApps().compactMap { app in
            guard let id = app.bundleIdentifier else { return nil }
            return AppRow(id: id, name: app.localizedName ?? id, icon: app.icon)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        rows.move(fromOffsets: source, toOffset: destination)
        OrderStore().setOrder(rows.map { $0.id })
    }
}
