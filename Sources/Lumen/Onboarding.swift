import SwiftUI

// MARK: - Shared page header
struct PageHeader: View {
    let title: String, subtitle: String
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.system(size: 30, weight: .bold))
            Text(subtitle).font(.title3).foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 40).padding(.bottom, 24).padding(.horizontal, 40)
    }
}

// MARK: - Onboarding flow with paged transitions
struct OnboardingView: View {
    var finish: () -> Void
    @State private var step = 0
    private let last = 4

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: WelcomePage()
                case 1: BackgroundPage()
                case 2: WidgetsPage()
                case 3: DurationPage()
                default: DonePage()
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            ZStack {
                HStack(spacing: 8) {
                    ForEach(0...last, id: \.self) { i in
                        Capsule().fill(i == step ? Color.primary : Color.secondary.opacity(0.3))
                            .frame(width: i == step ? 18 : 7, height: 7)
                    }
                }
                HStack {
                    if step > 0 && step < last {
                        Button("Zurück") { go(-1) }.controlSize(.large)
                    }
                    Spacer()
                    Button(step == last ? "Los geht’s" : "Weiter") { step == last ? finish() : go(1) }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .padding(20)
        }
        .frame(width: 860, height: 620)
    }

    private func go(_ d: Int) { withAnimation(.spring(duration: 0.5, bounce: 0.15)) { step += d } }
}

// MARK: - Welcome page
struct WelcomePage: View {
    private let features: [(String, String, String)] = [
        ("sparkles", "Lebendige Hintergründe", "Fünf animierte Szenen, flüssig und energiesparend gerendert."),
        ("square.grid.3x3.square", "Widgets nach Wunsch", "Uhr, Datum, Batterie und Bibelvers – in vier Stilen, frei platzierbar."),
        ("moon.zzz", "Startet von selbst", "Nach der gewählten Dauer ohne Aktivität. Eine Bewegung beendet ihn."),
    ]
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 120, height: 120).padding(.top, 36)
            PageHeader(title: "Willkommen bei Lumen", subtitle: "Ein Bildschirmschoner, der wirklich schön ist.").padding(.top, -24)
            VStack(alignment: .leading, spacing: 22) {
                ForEach(features, id: \.0) { f in
                    HStack(spacing: 18) {
                        Image(systemName: f.0).font(.system(size: 28)).foregroundStyle(.tint).frame(width: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(f.1).font(.headline)
                            Text(f.2).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: 460)
            Spacer()
        }
    }
}

// MARK: - Background picker page
struct BackgroundPage: View {
    @ObservedObject var s = Store.shared
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Wähle deinen Hintergrund", subtitle: "Alle Szenen bewegen sich sanft und endlos.")
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(230), spacing: 22), count: 3), spacing: 22) {
                ForEach(BG.allCases) { bg in
                    let sel = s.bg == bg
                    VStack(spacing: 10) {
                        BackgroundView(bg: bg)
                            .frame(width: 230, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.accentColor, lineWidth: sel ? 3 : 0))
                            .shadow(color: .black.opacity(sel ? 0.3 : 0.12), radius: sel ? 12 : 6, y: 4)
                            .scaleEffect(sel ? 1.03 : 1)
                        Label(bg.name, systemImage: sel ? "checkmark.circle.fill" : "circle")
                            .font(.headline).foregroundStyle(sel ? Color.accentColor : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.spring(duration: 0.35)) { s.bg = bg } }
                }
            }
            Spacer()
        }
    }
}

// MARK: - Position picker control
struct PositionPicker: View {
    @Binding var pos: Pos
    var body: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            ForEach(0..<3) { r in
                GridRow {
                    ForEach(0..<3) { c in
                        let p = Pos.allCases[r * 3 + c]
                        RoundedRectangle(cornerRadius: 2)
                            .fill(p == pos ? Color.accentColor : Color.secondary.opacity(0.25))
                            .frame(width: 14, height: 9)
                            .onTapGesture { withAnimation(.smooth) { pos = p } }
                    }
                }
            }
        }
        .padding(5)
        .background(RoundedRectangle(cornerRadius: 6).strokeBorder(.secondary.opacity(0.35)))
        .help("Position auf dem Bildschirm")
    }
}

// MARK: - Widgets page with live preview
struct WidgetsPage: View {
    @ObservedObject var s = Store.shared
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Widgets platzieren", subtitle: "Wähle Inhalte, Stil und Position – die Vorschau zeigt es live.")
            HStack(alignment: .top, spacing: 26) {
                VStack(spacing: 10) {
                    ForEach(s.widgets.indices, id: \.self) { i in
                        let w = s.widgets[i]
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: w.kind.symbol).frame(width: 22).foregroundStyle(.tint)
                                Text(w.kind.name).font(.headline)
                                Spacer()
                                Toggle("", isOn: $s.widgets[i].enabled.animation(.smooth)).toggleStyle(.switch).labelsHidden()
                            }
                            if w.enabled {
                                HStack {
                                    Picker("", selection: $s.widgets[i].style.animation(.smooth)) {
                                        ForEach(WStyle.allCases, id: \.self) { Text($0.name).tag($0) }
                                    }
                                    .pickerStyle(.segmented).labelsHidden()
                                    PositionPicker(pos: $s.widgets[i].pos)
                                }
                            }
                        }
                        .padding(12)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .frame(width: 360)
                SaverPreview(scale: 0.27)
            }
            Spacer()
        }
    }
}

// MARK: - Idle duration page
struct DurationPage: View {
    @ObservedObject var s = Store.shared
    private let options = [1, 2, 5, 10, 15, 30, 60, 0]
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Wann soll Lumen starten?", subtitle: "Nach dieser Zeit ohne Maus- oder Tastatureingabe.")
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(120), spacing: 16), count: 4), spacing: 16) {
                ForEach(options, id: \.self) { m in
                    let sel = s.idleMinutes == m
                    VStack(spacing: 2) {
                        Text(m == 0 ? "∞" : "\(m)").font(.system(size: 34, weight: .semibold, design: .rounded))
                        Text(m == 0 ? "Nur manuell" : m == 1 ? "Minute" : "Minuten").font(.callout).foregroundStyle(sel ? .white.opacity(0.85) : .secondary)
                    }
                    .frame(width: 120, height: 92)
                    .foregroundStyle(sel ? .white : .primary)
                    .background(sel ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.6)),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { s.idleMinutes = m } }
                }
            }
            Toggle("Lumen beim Anmelden automatisch öffnen", isOn: Binding(get: { s.launchAtLogin }, set: { s.launchAtLogin = $0 }))
                .toggleStyle(.switch).padding(.top, 30)
            Label("Zum Beenden einfach die Maus bewegen oder eine Taste drücken.", systemImage: "cursorarrow.motionlines")
                .foregroundStyle(.secondary).padding(.top, 14)
            Spacer()
        }
    }
}

// MARK: - Completion page
struct DonePage: View {
    @State private var appear = false
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 84)).foregroundStyle(.green)
                .symbolEffect(.bounce, value: appear)
                .scaleEffect(appear ? 1 : 0.5).opacity(appear ? 1 : 0)
            PageHeader(title: "Alles bereit.", subtitle: "Lumen wartet ab jetzt in der Menüleiste (✦).\nDort kannst du ihn jederzeit starten oder anpassen.")
            Button { SaverController.shared.show() } label: { Label("Vorschau ansehen", systemImage: "play.fill") }
                .controlSize(.large)
            Spacer()
        }
        .onAppear { withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.15)) { appear = true } }
    }
}
