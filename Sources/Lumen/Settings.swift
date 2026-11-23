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

// MARK: - Widget editor with drag canvas
struct EditorPage: View {
    @ObservedObject var s = Store.shared
    @State private var selection: UUID?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 14) {
                SaverCanvas(look: $s.look, fps: 30, editing: true, selection: $selection)
                    .aspectRatio(16 / 10, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
                HStack {
                    Menu {
                        ForEach(WKind.allCases) { k in Button { add(k) } label: { Label(k.name, systemImage: k.symbol) } }
                    } label: { Label("Widget hinzufügen", systemImage: "plus") }
                    .fixedSize()
                    Spacer()
                    Text("Ziehen zum Platzieren · die Mitte rastet ein").font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button { SaverController.shared.show() } label: { Label("Vorschau", systemImage: "play.fill") }
                }
                Spacer(minLength: 0)
            }
            .padding(24)
            Divider()
            Inspector(selection: $selection).frame(width: 300)
        }
    }

    private func add(_ k: WKind) {
        var it = WItem(k, .glass, 0.5, 0.5)
        it.scale = k == .clock ? 0.8 : 1
        s.look.items.append(it)
        selection = it.id
    }
}
