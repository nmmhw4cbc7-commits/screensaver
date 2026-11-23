import SwiftUI
import IOKit.pwr_mgt

// MARK: - Menu bar app entry point with quick designs
@main
struct LumenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        MenuBarExtra("Lumen", systemImage: "sparkles") {
            Button("Bildschirmschoner starten") { SaverController.shared.show() }
                .keyboardShortcut("s")
            Menu("Design") {
                ForEach(presets) { p in Button(p.name) { Store.shared.look = p.look } }
            }
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

// MARK: - App delegate managing windows
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate!
    private var win: NSWindow?

    func applicationDidFinishLaunching(_ n: Notification) {
        Self.shared = self
        SaverController.shared.start()
        let args = CommandLine.arguments
        if let i = args.firstIndex(of: "--preset"), i + 1 < args.count, let n = Int(args[i + 1]), presets.indices.contains(n) {
            Store.shared.look = presets[n].look
        }
        if args.contains("--preview") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { SaverController.shared.show() }
        } else if !Store.shared.onboarded { showOnboarding() }
    }

    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showSettings(); return false
    }

    private func present<V: View>(_ v: V, title: String, settings: Bool) {
        win?.close()
        var mask: NSWindow.StyleMask = [.titled, .closable, .fullSizeContentView]
        if settings { mask.formUnion([.miniaturizable, .resizable]) }
        let w = NSWindow(contentRect: .zero, styleMask: mask, backing: .buffered, defer: false)
        w.title = title
        w.titlebarAppearsTransparent = !settings
        w.titleVisibility = settings ? .visible : .hidden
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
        present(OnboardingView { [weak self] edit in
            Store.shared.onboarded = true
            self?.win?.close()
            if edit { self?.showSettings(.widgets) }
        }, title: "Willkommen", settings: false)
    }

    func showSettings(_ section: SettingsSection = .looks) {
        present(SettingsView(sel: section), title: "Lumen", settings: true)
    }
}

// MARK: - Key-capable full-screen window
final class SaverWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Idle detection, video awareness and display sleep
final class SaverController {
    static let shared = SaverController()
    private var windows: [NSWindow] = []
    private var shownAt = Date.distantPast
    private var timer: Timer?
    private var monitor: Any?
    private var prevApp: NSRunningApplication?
    private var startMouse = NSPoint.zero
    private var cursorHidden = false
    private var slept = false

    private var idle: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    /// true while e.g. a video or presentation keeps the display awake
    private var displayBusy: Bool {
        var d: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsStatus(&d) == kIOReturnSuccess,
              let dict = d?.takeRetainedValue() as? [String: Int] else { return false }
        return (dict["PreventUserIdleDisplaySleep"] ?? 0) > 0
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let s = Store.shared
        if windows.isEmpty {
            guard s.idleMinutes > 0, idle >= Double(s.idleMinutes * 60) else { return }
            if s.skipVideo && displayBusy { return }
            show()
            return
        }
        let running = Date().timeIntervalSince(shownAt)
        if !NSApp.isActive, running > 2, idle < 0.5 { hide(); return }
        if s.displaySleep > 0, !slept, running > Double(s.displaySleep * 60) {
            slept = true
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            p.arguments = ["displaysleepnow"]
            try? p.run()
        }
    }
}
