import SwiftUI

// MARK: - Settings sidebar sections
enum SettingsSection: String, CaseIterable, Identifiable {
    case clock, background, style, behavior, about
    var id: String { rawValue }
    var name: String { ["Uhr", "Hintergrund", "Stil", "Verhalten", "Über Lumen"][Self.allCases.firstIndex(of: self)!] }
    var symbol: String { ["clock", "photo.on.rectangle", "textformat", "timer", "info.circle"][Self.allCases.firstIndex(of: self)!] }
}

struct SettingsView: View {
    @ObservedObject var s = Store.shared
    @State var sel: SettingsSection?

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $sel) { Label($0.name, systemImage: $0.symbol).tag($0) }
                .navigationSplitViewColumnWidth(180)
        } detail: {
            let section = sel ?? .clock
            VStack(spacing: 0) {
                if [.clock, .background, .style].contains(section) {
                    HStack {
                        LookThumb(look: s.look, width: 520, fps: 30).shadow(color: .black.opacity(0.25), radius: 14, y: 6)
                        Button { SaverController.shared.show() } label: { Label("Vorschau", systemImage: "play.fill") }
                            .controlSize(.large).padding(.leading, 20)
                    }
                    .padding(.vertical, 20)
                }
                switch section {
                case .clock: FacesPage(header: false)
                case .background: BackgroundPage(header: false)
                case .style: StylePage()
                case .behavior: BehaviorPage()
                case .about: AboutPage()
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 820)
    }
}
