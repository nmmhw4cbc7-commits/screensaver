import SwiftUI

// MARK: - Settings sidebar sections
enum SettingsSection: String, CaseIterable, Identifiable {
    case looks, background, widgets, behavior, about
    var id: String { rawValue }
    var name: String { ["Designs", "Hintergrund", "Widgets", "Verhalten", "Über Lumen"][Self.allCases.firstIndex(of: self)!] }
    var symbol: String { ["wand.and.stars", "photo.on.rectangle", "square.grid.3x3.square", "timer", "info.circle"][Self.allCases.firstIndex(of: self)!] }
}

struct SettingsView: View {
    @State var sel: SettingsSection?
    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $sel) { Label($0.name, systemImage: $0.symbol).tag($0) }
                .navigationSplitViewColumnWidth(190)
        } detail: {
            switch sel ?? .looks {
            case .looks: LooksPage()
            case .background: BackgroundPage()
            case .widgets: EditorPage()
            case .behavior: BehaviorPage()
            case .about: AboutPage()
            }
        }
        .frame(minWidth: 1120, minHeight: 720)
    }
}
