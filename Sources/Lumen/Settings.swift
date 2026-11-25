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

// MARK: - Clock face gallery
struct FacesPage: View {
    @ObservedObject var s = Store.shared
    var header = true
    var body: some View {
        VStack(spacing: 0) {
            if header { PageHeader(title: "Wähle deine Uhr", subtitle: "16 Zifferblätter – kombinierbar mit jedem Hintergrund.") }
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(180), spacing: 16), count: 4), spacing: 16) {
                    ForEach(Face.allCases) { f in
                        let sel = s.look.face == f
                        VStack(spacing: 6) {
                            FaceThumb(look: s.look, face: f, width: 180)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.accentColor, lineWidth: sel ? 3 : 0))
                                .shadow(color: .black.opacity(sel ? 0.3 : 0.1), radius: sel ? 10 : 4, y: 3)
                            Text(f.name).font(.callout.weight(.medium)).foregroundStyle(sel ? Color.accentColor : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.smooth) { s.look.face = f } }
                    }
                }
                .padding(.vertical, 12)
            }
        }
    }
}
