import SwiftUI
import IOKit.ps

// MARK: - Rotating Bible verses
private let verses: [(String, String)] = [
    ("Der Herr ist mein Hirte, mir wird nichts mangeln.", "Psalm 23,1"),
    ("Seid stille und erkennt, dass ich Gott bin.", "Psalm 46,11"),
    ("Dein Wort ist meines Fußes Leuchte und ein Licht auf meinem Wege.", "Psalm 119,105"),
    ("Alle eure Sorge werft auf ihn; denn er sorgt für euch.", "1. Petrus 5,7"),
    ("Ich vermag alles durch den, der mich mächtig macht.", "Philipper 4,13"),
    ("Kommt her zu mir, alle, die ihr mühselig und beladen seid; ich will euch erquicken.", "Matthäus 11,28"),
    ("Die auf den Herrn harren, kriegen neue Kraft.", "Jesaja 40,31"),
    ("Ich bin das Licht der Welt.", "Johannes 8,12"),
    ("Fürchte dich nicht, denn ich bin mit dir.", "Jesaja 41,10"),
    ("Gott ist Liebe.", "1. Johannes 4,16"),
]

// MARK: - Battery status via IOKit
private func battery() -> (Int, Bool)? {
    guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
    for ps in list {
        if let d = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
           let cap = d[kIOPSCurrentCapacityKey] as? Int {
            return (cap, d[kIOPSIsChargingKey] as? Bool ?? false)
        }
    }
    return nil
}

// MARK: - Widget view with live data and styles
struct WidgetView: View {
    let conf: WConf

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in content(tl.date) }
    }

    private func data(_ d: Date) -> (String?, String, String?) {
        switch conf.kind {
        case .clock:
            return (nil, d.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute()), nil)
        case .date:
            return (nil, d.formatted(.dateTime.weekday(.wide)), d.formatted(.dateTime.day().month(.wide).year()))
        case .battery:
            guard let (p, ch) = battery() else { return ("powerplug", "Netzbetrieb", nil) }
            let sym = ch ? "battery.100percent.bolt" : ["battery.0percent", "battery.25percent", "battery.50percent", "battery.75percent", "battery.100percent"][min(4, (p + 12) / 25)]
            return (sym, "\(p) %", ch ? "Lädt" : nil)
        case .verse:
            let v = verses[Int(d.timeIntervalSince1970 / 300) % verses.count]
            return (nil, "„\(v.0)“", v.1)
        }
    }

    private func font(_ size: CGFloat, _ secondary: Bool = false) -> Font {
        switch conf.style {
        case .glass: .system(size: size, weight: secondary ? .medium : .semibold, design: .rounded)
        case .minimal: .system(size: size, weight: secondary ? .light : .thin)
        case .bold: .system(size: size * 1.08, weight: secondary ? .bold : .black)
        case .mono: .system(size: size * 0.82, weight: secondary ? .regular : .medium, design: .monospaced)
        }
    }

    @ViewBuilder private func content(_ d: Date) -> some View {
        let (sym, main, sub) = data(d)
        let size: CGFloat = conf.kind == .clock ? 132 : conf.kind == .verse ? 26 : 40
        let align: HorizontalAlignment = conf.pos.hAlign
        VStack(alignment: align, spacing: conf.kind == .clock ? 0 : 6) {
            HStack(spacing: 12) {
                if let sym { Image(systemName: sym).font(.system(size: size * 0.7)) }
                Text(main).font(font(size)).monospacedDigit().contentTransition(.numericText())
            }
            if let sub { Text(sub).font(font(size * 0.55, true)).opacity(0.75) }
        }
        .multilineTextAlignment(align == .leading ? .leading : align == .trailing ? .trailing : .center)
        .frame(maxWidth: conf.kind == .verse ? 560 : nil)
        .fixedSize(horizontal: false, vertical: true)
        .foregroundStyle(.white)
        .textCase(conf.style == .mono ? .uppercase : nil)
        .modifier(StyleMod(style: conf.style))
        .animation(.smooth, value: main)
    }
}

// MARK: - Glass, minimal, bold and mono style modifiers
private struct StyleMod: ViewModifier {
    let style: WStyle
    func body(content: Content) -> some View {
        switch style {
        case .glass:
            content.padding(.horizontal, 28).padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.18)))
                .environment(\.colorScheme, .dark)
        case .minimal:
            content.shadow(color: .black.opacity(0.25), radius: 12)
        case .bold:
            content.shadow(color: .black.opacity(0.5), radius: 24, y: 6)
        case .mono:
            content.tracking(2).padding(.horizontal, 22).padding(.vertical, 16)
                .overlay(Rectangle().strokeBorder(.white.opacity(0.55), lineWidth: 1))
        }
    }
}

// MARK: - Full-screen saver composition with burn-in drift
struct SaverView: View {
    @ObservedObject var s = Store.shared
    var body: some View {
        ZStack {
            BackgroundView(bg: s.bg)
            TimelineView(.periodic(from: .now, by: 4)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Pos.allCases) { p in
                        let ws = s.widgets.filter { $0.enabled && $0.pos == p }
                        if !ws.isEmpty {
                            VStack(alignment: p.hAlign, spacing: 22) { ForEach(ws) { WidgetView(conf: $0) } }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: p.alignment)
                        }
                    }
                }
                .padding(80)
                .offset(x: 14 * sin(t / 40), y: 10 * cos(t / 53))
                .animation(.easeInOut(duration: 4), value: t)
            }
        }
        .ignoresSafeArea()
    }
}
