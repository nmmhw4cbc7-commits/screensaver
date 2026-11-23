import SwiftUI

// MARK: - Menu bar app entry point
@main
struct LumenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        MenuBarExtra("Lumen", systemImage: "sparkles") {
            Button("Bildschirmschoner starten") { SaverController.shared.show() }
                .keyboardShortcut("s")
            Divider()
            Button("Einstellungen …") { AppDelegate.shared.showSettings() }
                .keyboardShortcut(",")
            Button("Einführung anzeigen") { AppDelegate.shared.showOnboarding() }
            Divider()
            Button("Lumen beenden") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        }
    }
}

// MARK: - App delegate managing onboarding and settings windows
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    private var win: NSWindow?

    func applicationDidFinishLaunching(_ n: Notification) {
        Self.shared = self
        SaverController.shared.start()
        if !Store.shared.onboarded { showOnboarding() }
    }

    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings(); return false
    }

    private func present<V: View>(_ v: V, title: String, chrome: Bool) {
        win?.close()
        let w = NSWindow(contentRect: .zero, styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
        w.title = title
        w.titlebarAppearsTransparent = !chrome
        w.titleVisibility = chrome ? .visible : .hidden
        w.isReleasedWhenClosed = false
        let host = NSHostingController(rootView: v)
        w.contentViewController = host
        w.setContentSize(host.view.fittingSize)
        w.center()
        win = w
        NSApp.activate(ignoringOtherApps: true)
        w.makeKeyAndOrderFront(nil)
    }

    func showOnboarding() {
        present(OnboardingView { [weak self] in
            Store.shared.onboarded = true
            self?.win?.close()
        }, title: "Willkommen", chrome: false)
    }

    func showSettings() {
        present(SettingsView(), title: "Lumen Einstellungen", chrome: true)
    }
}

// MARK: - Idle detection and saver activation
final class SaverController {
    static let shared = SaverController()
    private var windows: [NSWindow] = []
    private var shownAt = Date.distantPast
    private var timer: Timer?

    private var idle: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let mins = Store.shared.idleMinutes
        if windows.isEmpty {
            if mins > 0, idle >= Double(mins * 60) { show() }
        } else if Date().timeIntervalSince(shownAt) > 2, idle < 0.6 {
            hide()
        }
    }

    // MARK: - Multi-display saver windows with fade transitions
    func show() {
        guard windows.isEmpty else { return }
        shownAt = Date()
        for screen in NSScreen.screens {
            let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.isReleasedWhenClosed = false
            w.backgroundColor = .black
            w.contentView = NSHostingView(rootView: SaverView())
            w.setFrame(screen.frame, display: true)
            w.alphaValue = 0
            w.orderFrontRegardless()
            windows.append(w)
        }
        NSCursor.hide()
        NSAnimationContext.runAnimationGroup { $0.duration = 1.2; windows.forEach { $0.animator().alphaValue = 1 } }
    }

    func hide() {
        let ws = windows
        windows = []
        NSCursor.unhide()
        NSAnimationContext.runAnimationGroup({ $0.duration = 0.35; ws.forEach { $0.animator().alphaValue = 0 } }) {
            ws.forEach { $0.contentView = nil; $0.close() }
        }
    }
}
