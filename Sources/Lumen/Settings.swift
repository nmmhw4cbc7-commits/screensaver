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

// MARK: - Inspector for the selected widget
struct Inspector: View {
    @ObservedObject var s = Store.shared
    @Binding var selection: UUID?

    var body: some View {
        if let id = selection, let item = s.look.items.first(where: { $0.id == id }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label(item.kind.name, systemImage: item.kind.symbol).font(.title3.bold())
                    group("Stil") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                            ForEach(WStyle.allCases) { st in
                                let on = item.style == st
                                Text(st.name).font(.callout.weight(.medium))
                                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                                    .foregroundStyle(on ? .white : .primary)
                                    .background(on ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary), in: RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { bind(\.style, id, item.style).wrappedValue = st }
                            }
                        }
                    }
                    group("Farbe") {
                        HStack(spacing: 9) {
                            ForEach(tints.indices, id: \.self) { t in
                                Circle().fill(tints[t]).frame(width: 24, height: 24)
                                    .overlay(Circle().strokeBorder(.primary.opacity(0.2)))
                                    .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: item.tint == t ? 2.5 : 0).padding(-4))
                                    .onTapGesture { bind(\.tint, id, 0).wrappedValue = t }
                            }
                        }
                    }
                    group("Größe") { Slider(value: bind(\.scale, id, 1), in: 0.4...2.2) }
                    params(item, id)
                    Divider()
                    HStack {
                        Button { duplicate(item) } label: { Label("Duplizieren", systemImage: "plus.square.on.square") }
                        Spacer()
                        Button(role: .destructive) {
                            selection = nil
                            s.look.items.removeAll { $0.id == id }
                        } label: { Label("Entfernen", systemImage: "trash") }
                    }
                }
                .padding(20)
            }
        } else {
            ContentUnavailableView("Kein Widget ausgewählt", systemImage: "cursorarrow.click.2",
                                   description: Text("Klicke ein Widget in der Vorschau an oder füge ein neues hinzu."))
        }
    }

    // MARK: - Per-widget parameters
    @ViewBuilder private func params(_ item: WItem, _ id: UUID) -> some View {
        switch item.kind {
        case .weather:
            group("Ort") { TextField("Stadt", text: bind(\.param, id, "")).textFieldStyle(.roundedBorder) }
        case .world:
            group("Zeitzone") {
                Picker("", selection: bind(\.param, id, "")) {
                    ForEach(zones, id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ")).tag($0) }
                }
                .labelsHidden()
            }
        case .countdown:
            group("Ereignis") {
                TextField("Titel", text: bind(\.param, id, "")).textFieldStyle(.roundedBorder)
                DatePicker("", selection: bind(\.date, id, .now)).labelsHidden()
            }
        case .greeting:
            group("Name") { TextField("Name", text: bind(\.param, id, "")).textFieldStyle(.roundedBorder) }
        case .text:
            group("Text") { TextField("Text", text: bind(\.param, id, ""), axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder) }
        default:
            EmptyView()
        }
    }

    private func group<C: View>(_ title: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            c()
        }
    }

    private func bind<T>(_ kp: WritableKeyPath<WItem, T>, _ id: UUID, _ def: T) -> Binding<T> {
        Binding(get: { s.look.items.first { $0.id == id }?[keyPath: kp] ?? def },
                set: { v in if let i = s.look.items.firstIndex(where: { $0.id == id }) { s.look.items[i][keyPath: kp] = v } })
    }

    private func duplicate(_ item: WItem) {
        var c = item
        c.id = UUID()
        c.x = min(0.95, item.x + 0.05); c.y = min(0.95, item.y + 0.05)
        s.look.items.append(c)
        selection = c.id
    }
}
