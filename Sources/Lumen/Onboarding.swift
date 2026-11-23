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
