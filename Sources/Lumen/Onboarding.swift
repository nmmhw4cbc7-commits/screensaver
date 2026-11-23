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
        .padding(.top, 36).padding(.bottom, 22).padding(.horizontal, 40)
    }
}

// MARK: - Onboarding flow with paged transitions
struct OnboardingView: View {
    var finish: (_ openEditor: Bool) -> Void
    @State private var step = 0
    private let last = 4

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: WelcomePage()
                case 1: LooksPage()
                case 2: BackgroundPage()
                case 3: BehaviorPage()
                default: DonePage(edit: { finish(true) })
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
                    if step > 0 && step < last { Button("Zurück") { go(-1) }.controlSize(.large) }
                    Spacer()
                    Button(step == last ? "Los geht’s" : "Weiter") { step == last ? finish(false) : go(1) }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent).controlSize(.large)
                }
            }
            .padding(20)
        }
        .frame(width: 940, height: 680)
    }

    private func go(_ d: Int) { withAnimation(.spring(duration: 0.5, bounce: 0.15)) { step += d } }
}

// MARK: - Welcome page
struct WelcomePage: View {
    private let features: [(String, String, String)] = [
        ("sparkles", "12 lebendige Hintergründe", "Von Aurora bis Sternenflug – oder deine eigenen Fotos."),
        ("square.grid.3x3.square", "14 Widgets, 9 Stile, 8 Farben", "Uhr, Wetter, Weltzeit, Kalender, Countdown und mehr – frei platzierbar."),
        ("wand.and.stars", "Fertige Designs", "Ein Klick für einen perfekt abgestimmten Look."),
        ("moon.zzz", "Startet von selbst", "Pausiert bei Videos, schläft den Bildschirm auf Wunsch ein."),
    ]
    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 116, height: 116).padding(.top, 34)
            PageHeader(title: "Willkommen bei Lumen", subtitle: "Dein Bildschirm, wenn du gerade nicht hinsiehst.").padding(.top, -22)
            VStack(alignment: .leading, spacing: 20) {
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
            .frame(maxWidth: 500)
            Spacer()
        }
    }
}

// MARK: - Design preset gallery
struct LooksPage: View {
    @ObservedObject var s = Store.shared
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Wähle ein Design", subtitle: "Ein Startpunkt – alles lässt sich später anpassen.")
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(200), spacing: 18), count: 4), spacing: 18) {
                    ForEach(presets) { p in
                        let sel = s.look == p.look
                        VStack(spacing: 8) {
                            LookThumb(look: p.look, width: 200)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.accentColor, lineWidth: sel ? 3 : 0))
                                .shadow(color: .black.opacity(sel ? 0.3 : 0.12), radius: sel ? 10 : 5, y: 3)
                            Text(p.name).font(.headline).foregroundStyle(sel ? Color.accentColor : .primary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.spring(duration: 0.35)) { s.look = p.look } }
                    }
                }
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Background picker with tuning sliders
struct BackgroundPage: View {
    @ObservedObject var s = Store.shared
    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "Hintergrund", subtitle: "Alle Szenen bewegen sich sanft und endlos.")
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(160), spacing: 16), count: 4), spacing: 14) {
                ForEach(BG.allCases) { bg in
                    let sel = s.look.bg == bg
                    VStack(spacing: 6) {
                        BackgroundView(bg: bg, fps: 15)
                            .frame(width: 160, height: 92)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.accentColor, lineWidth: sel ? 3 : 0))
                        Text(bg.name).font(.callout.weight(.medium)).foregroundStyle(sel ? Color.accentColor : .primary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.smooth) { s.look.bg = bg } }
                }
            }
            HStack(spacing: 28) {
                slider("Tempo", "tortoise", $s.look.speed, 0.2...3)
                slider("Farbton", "paintpalette", $s.look.hue, 0...1)
                slider("Abdunkeln", "moon", $s.look.dim, 0...0.8)
            }
            .padding(.horizontal, 60).padding(.top, 22)
            if s.look.bg == .photos {
                HStack {
                    Text(s.photoFolder.isEmpty ? "Kein Ordner gewählt" : (s.photoFolder as NSString).abbreviatingWithTildeInPath)
                        .foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                    Button("Fotoordner wählen …") { pickFolder() }
                }
                .padding(.top, 12)
            }
            Spacer()
        }
    }

    private func slider(_ title: String, _ sym: String, _ v: Binding<Double>, _ r: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: sym).font(.callout).foregroundStyle(.secondary)
            Slider(value: v, in: r)
        }
    }

    private func pickFolder() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true
        p.canChooseFiles = false
        p.prompt = "Auswählen"
        if p.runModal() == .OK, let u = p.url { s.photoFolder = u.path }
    }
}

// MARK: - Behavior page: duration, video pause, display sleep
struct BehaviorPage: View {
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
                        Text(m == 0 ? "Nur manuell" : m == 1 ? "Minute" : "Minuten").font(.callout)
                            .foregroundStyle(sel ? .white.opacity(0.85) : .secondary)
                    }
                    .frame(width: 120, height: 88)
                    .foregroundStyle(sel ? .white : .primary)
                    .background(sel ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary.opacity(0.6)),
                                in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .contentShape(Rectangle())
                    .onTapGesture { withAnimation(.spring(duration: 0.3)) { s.idleMinutes = m } }
                }
            }
            Form {
                Toggle("Nicht starten, während Videos oder Präsentationen laufen", isOn: $s.skipVideo)
                Picker("Bildschirm danach ausschalten", selection: $s.displaySleep) {
                    Text("Nie").tag(0)
                    ForEach([5, 10, 20, 30, 60], id: \.self) { Text("nach \($0) Min.").tag($0) }
                }
                Toggle("Lumen beim Anmelden öffnen", isOn: Binding(get: { s.launchAtLogin }, set: { s.launchAtLogin = $0 }))
            }
            .formStyle(.grouped)
            .frame(width: 540)
            .scrollDisabled(true)
            Spacer()
        }
    }
}

// MARK: - Completion page
struct DonePage: View {
    var edit: () -> Void
    @State private var appear = false
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 84)).foregroundStyle(.green)
                .symbolEffect(.bounce, value: appear)
                .scaleEffect(appear ? 1 : 0.5).opacity(appear ? 1 : 0)
            PageHeader(title: "Alles bereit.", subtitle: "Lumen wartet ab jetzt in der Menüleiste (✦).")
            HStack(spacing: 12) {
                Button { SaverController.shared.show() } label: { Label("Vorschau", systemImage: "play.fill") }
                Button { edit() } label: { Label("Widgets anpassen", systemImage: "slider.horizontal.3") }
            }
            .controlSize(.large)
            Spacer()
        }
        .onAppear { withAnimation(.spring(duration: 0.6, bounce: 0.4).delay(0.15)) { appear = true } }
    }
}
