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
