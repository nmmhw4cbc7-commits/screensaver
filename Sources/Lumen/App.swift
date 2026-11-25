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
            Menu("Uhr") {
                ForEach(Face.allCases) { f in Button(f.name) { Store.shared.look.face = f } }
            }
            Menu("Hintergrund") {
                ForEach(BG.allCases) { b in Button(b.name) { Store.shared.look.bg = b } }
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
        if let i = args.firstIndex(of: "--face"), i + 1 < args.count, let n = Int(args[i + 1]), Face.allCases.indices.contains(n) {
            Store.shared.look.face = Face.allCases[n]
        }
        if let i = args.firstIndex(of: "--bg"), i + 1 < args.count, let n = Int(args[i + 1]), BG.allCases.indices.contains(n) {
            Store.shared.look.bg = BG.allCases[n]
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
            if edit { self?.showSettings(.style) }
        }, title: "Willkommen", settings: false)
    }

    func showSettings(_ section: SettingsSection = .clock) {
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

    // MARK: - Show and dismiss with event capture
    func show() {
        guard windows.isEmpty else { return }
        shownAt = Date()
        slept = false
        prevApp = NSWorkspace.shared.frontmostApplication
        NSApp.activate(ignoringOtherApps: true)
        for screen in NSScreen.screens {
            let w = SaverWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
            w.level = .screenSaver
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            w.isReleasedWhenClosed = false
            w.backgroundColor = .black
            w.acceptsMouseMovedEvents = true
            w.contentView = NSHostingView(rootView: SaverCanvas(look: Store.shared.look))
            w.setFrame(screen.frame, display: true)
            w.alphaValue = 0
            windows.append(w)
        }
        windows.first?.makeKeyAndOrderFront(nil)
        windows.dropFirst().forEach { $0.orderFrontRegardless() }
        if !cursorHidden { NSCursor.hide(); cursorHidden = true }
        startMouse = NSEvent.mouseLocation
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel, .mouseMoved]) { [weak self] e in
            guard let self else { return e }
            if e.type == .mouseMoved {
                let p = NSEvent.mouseLocation
                if hypot(p.x - self.startMouse.x, p.y - self.startMouse.y) < 14 { return nil }
            }
            if Date().timeIntervalSince(self.shownAt) > 0.8 { self.hide() }
            return nil
        }
        NSAnimationContext.runAnimationGroup { $0.duration = 1.2; windows.forEach { $0.animator().alphaValue = 1 } }
    }

    func hide() {
        guard !windows.isEmpty else { return }
        let ws = windows
        windows = []
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        if cursorHidden { NSCursor.unhide(); cursorHidden = false }
        NSAnimationContext.runAnimationGroup({ $0.duration = 0.35; ws.forEach { $0.animator().alphaValue = 0 } }) {
            ws.forEach { $0.contentView = nil; $0.close() }
        }
        prevApp?.activate()
    }
}
