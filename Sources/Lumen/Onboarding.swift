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
