import SwiftUI
import IOKit.ps

// MARK: - Weather via Open-Meteo (no API key)
final class Weather {
    static let shared = Weather()
    struct Now { var temp, hi, lo: Double; var code: Int }
    private var data: [String: Now] = [:]
    private var fetched: [String: Date] = [:]

    func get(_ city: String) -> Now? {
        if Date().timeIntervalSince(fetched[city] ?? .distantPast) > 1800 {
            fetched[city] = Date()
            Task { await load(city) }
        }
        return data[city]
    }

    private func load(_ city: String) async {
        guard let q = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let g = try? await json("https://geocoding-api.open-meteo.com/v1/search?count=1&language=de&name=\(q)"),
              let r = (g["results"] as? [[String: Any]])?.first,
              let lat = r["latitude"] as? Double, let lon = r["longitude"] as? Double,
              let f = try? await json("https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=1"),
              let cur = f["current"] as? [String: Any], let d = f["daily"] as? [String: Any]
        else { fetched[city] = Date().addingTimeInterval(-1700); return }
        let n = Now(temp: cur["temperature_2m"] as? Double ?? 0,
                    hi: (d["temperature_2m_max"] as? [Double])?.first ?? 0,
                    lo: (d["temperature_2m_min"] as? [Double])?.first ?? 0,
                    code: cur["weather_code"] as? Int ?? 0)
        await MainActor.run { self.data[city] = n }
    }

    private func json(_ s: String) async throws -> [String: Any] {
        let (d, _) = try await URLSession.shared.data(from: URL(string: s)!)
        return try JSONSerialization.jsonObject(with: d) as? [String: Any] ?? [:]
    }

    static func describe(_ c: Int) -> (String, String) {
        switch c {
        case 0: return ("sun.max.fill", "Klar")
        case 1, 2: return ("cloud.sun.fill", "Leicht bewölkt")
        case 3: return ("cloud.fill", "Bewölkt")
        case 45, 48: return ("cloud.fog.fill", "Nebel")
        case 51...67: return ("cloud.rain.fill", "Regen")
        case 71...77, 85, 86: return ("cloud.snow.fill", "Schnee")
        case 80...82: return ("cloud.heavyrain.fill", "Schauer")
        case 95...99: return ("cloud.bolt.rain.fill", "Gewitter")
        default: return ("cloud.sun.fill", "Wechselhaft")
        }
    }
}

// MARK: - System, battery, moon and quote data
enum Sys {
    static func cpu() -> Double {
        var l = [Double](repeating: 0, count: 3)
        getloadavg(&l, 3)
        return min(1, l[0] / Double(ProcessInfo.processInfo.activeProcessorCount))
    }

    static func mem() -> Double {
        var s = vm_statistics64()
        var c = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &s) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(c)) { host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &c) } }
        guard r == KERN_SUCCESS else { return 0 }
        let used = Double(UInt64(s.active_count) + UInt64(s.wire_count) + UInt64(s.compressor_page_count)) * Double(vm_kernel_page_size)
        return min(1, used / Double(ProcessInfo.processInfo.physicalMemory))
    }

    static func battery() -> (Int, Bool)? {
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

    static func moon(_ d: Date) -> (String, String, Double) {
        let age = fract((d.timeIntervalSince1970 - 947_182_440) / 86400 / 29.530588853)
        let i = Int((age * 8).rounded()) % 8
        let names = ["Neumond", "Zunehmende Sichel", "Erstes Viertel", "Zunehmender Mond", "Vollmond", "Abnehmender Mond", "Letztes Viertel", "Abnehmende Sichel"]
        let syms = ["new.moon", "waxing.crescent", "first.quarter", "waxing.gibbous", "full.moon", "waning.gibbous", "last.quarter", "waning.crescent"]
        return ("moonphase." + syms[i], names[i], (1 - cos(age * 2 * .pi)) / 2)
    }

    static let quotes: [(String, String)] = [
        ("Es ist nicht wenig Zeit, die wir haben, sondern viel Zeit, die wir nicht nutzen.", "Seneca"),
        ("Auch aus Steinen, die einem in den Weg gelegt werden, kann man Schönes bauen.", "Goethe"),
        ("Eine Reise von tausend Meilen beginnt mit dem ersten Schritt.", "Laozi"),
        ("Das Glück deines Lebens hängt von der Beschaffenheit deiner Gedanken ab.", "Marc Aurel"),
        ("Phantasie ist wichtiger als Wissen.", "Albert Einstein"),
        ("Einfachheit ist die höchste Stufe der Vollendung.", "Leonardo da Vinci"),
        ("Nicht weil es schwer ist, wagen wir es nicht, sondern weil wir es nicht wagen, ist es schwer.", "Seneca"),
        ("Die Zukunft hängt davon ab, was wir heute tun.", "Mahatma Gandhi"),
        ("Wer immer tut, was er schon kann, bleibt immer das, was er schon ist.", "Henry Ford"),
        ("Tu erst das Notwendige, dann das Mögliche, und plötzlich schaffst du das Unmögliche.", "Franz von Assisi"),
        ("In der Ruhe liegt die Kraft.", "Sprichwort"),
        ("Wer aufhört, besser zu werden, hat aufgehört, gut zu sein.", "Philip Rosenthal"),
    ]
}

// MARK: - Style kit: fonts and colors per style
struct StyleKit {
    let style: WStyle
    let tint: Color
    var fg: Color { style == .color ? Color.black.opacity(0.82) : tint }

    func font(_ size: CGFloat, _ secondary: Bool = false) -> Font {
        switch style {
        case .glass, .card: return .system(size: size, weight: secondary ? .medium : .semibold, design: .rounded)
        case .minimal: return .system(size: size, weight: secondary ? .light : .thin)
        case .bold: return .system(size: size * 1.08, weight: secondary ? .bold : .black)
        case .mono: return .system(size: size * 0.82, weight: secondary ? .regular : .medium, design: .monospaced)
        case .neon: return .system(size: size, weight: secondary ? .medium : .bold, design: .rounded)
        case .serif: return .system(size: size, weight: secondary ? .regular : .medium, design: .serif)
        case .outline: return .system(size: size, weight: secondary ? .regular : .light, design: .rounded)
        case .color: return .system(size: size, weight: secondary ? .semibold : .heavy, design: .rounded)
        }
    }
}

// MARK: - Chrome modifier for all nine styles
struct Chrome: ViewModifier {
    let kit: StyleKit
    func body(content: Content) -> some View {
        let c = content.foregroundStyle(kit.fg).textCase(kit.style == .mono ? .uppercase : nil)
        switch kit.style {
        case .glass:
            c.padding(.horizontal, 28).padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.18)))
                .environment(\.colorScheme, .dark)
        case .minimal, .serif:
            c.shadow(color: .black.opacity(0.3), radius: 12)
        case .bold:
            c.shadow(color: .black.opacity(0.5), radius: 24, y: 6)
        case .mono:
            c.tracking(2).padding(.horizontal, 22).padding(.vertical, 16)
                .overlay(Rectangle().strokeBorder(kit.tint.opacity(0.55), lineWidth: 1))
        case .neon:
            c.shadow(color: kit.tint, radius: 3).shadow(color: kit.tint.opacity(0.8), radius: 14).shadow(color: kit.tint.opacity(0.5), radius: 34)
        case .outline:
            c.padding(.horizontal, 26).padding(.vertical, 18)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(kit.tint.opacity(0.8), lineWidth: 2))
        case .card:
            c.padding(.leading, 46).padding(.trailing, 30).padding(.vertical, 20)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(alignment: .leading) { Capsule().fill(kit.tint).frame(width: 4).padding(.vertical, 18).padding(.leading, 14) }
        case .color:
            c.padding(.horizontal, 28).padding(.vertical, 20)
                .background(kit.tint.opacity(0.92), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        }
    }
}

// MARK: - Building blocks: info text, ring, analog face, month grid
struct Info: View {
    let kit: StyleKit
    var sym: String? = nil
    let main: String
    var sub: String? = nil
    var size: CGFloat = 40
    var width: CGFloat? = nil

    var body: some View {
        VStack(spacing: size > 90 ? 0 : 6) {
            HStack(spacing: 12) {
                if let sym { Image(systemName: sym).symbolRenderingMode(.hierarchical).font(.system(size: size * 0.75)) }
                Text(main).font(kit.font(size)).monospacedDigit().contentTransition(.numericText())
            }
            if let sub, !sub.isEmpty { Text(sub).font(kit.font(max(15, size * 0.42), true)).opacity(0.75) }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: width)
        .fixedSize(horizontal: width == nil, vertical: true)
    }
}

struct Ring: View {
    let kit: StyleKit
    let value: Double
    let label: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().stroke(kit.fg.opacity(0.2), lineWidth: 8)
                Circle().trim(from: 0, to: value).stroke(kit.fg, style: StrokeStyle(lineWidth: 8, lineCap: .round)).rotationEffect(.degrees(-90))
                Text("\(Int(value * 100))").font(kit.font(22)).monospacedDigit()
            }
            .frame(width: 78, height: 78)
            Text(label).font(kit.font(15, true)).opacity(0.75)
        }
    }
}

struct AnalogClock: View {
    let date: Date
    let kit: StyleKit
    var body: some View {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let s = Double(c.second ?? 0)
        let m = Double(c.minute ?? 0) + s / 60
        let h = Double(c.hour ?? 0).truncatingRemainder(dividingBy: 12) + m / 60
        ZStack {
            Circle().strokeBorder(kit.fg.opacity(0.35), lineWidth: 2)
            ForEach(0..<12, id: \.self) { i in
                Capsule().fill(kit.fg.opacity(i % 3 == 0 ? 0.9 : 0.45))
                    .frame(width: i % 3 == 0 ? 4 : 2, height: i % 3 == 0 ? 16 : 10)
                    .offset(y: -88)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            hand(h / 12, 52, 6, kit.fg)
            hand(m / 60, 76, 4, kit.fg)
            hand(s / 60, 84, 2, .orange)
            Circle().fill(.orange).frame(width: 10, height: 10)
        }
        .frame(width: 210, height: 210)
    }

    private func hand(_ v: Double, _ len: CGFloat, _ w: CGFloat, _ col: Color) -> some View {
        Capsule().fill(col).frame(width: w, height: len).offset(y: -len / 2).rotationEffect(.degrees(v * 360))
    }
}

struct MonthView: View {
    let date: Date
    let kit: StyleKit
    var body: some View {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let days = cal.range(of: .day, in: .month, for: date)!.count
        let lead = (cal.component(.weekday, from: start) - cal.firstWeekday + 7) % 7
        let today = cal.component(.day, from: date)
        let sy = cal.veryShortStandaloneWeekdaySymbols
        let wd = Array(sy[(cal.firstWeekday - 1)...] + sy[..<(cal.firstWeekday - 1)])
        VStack(spacing: 10) {
            Text(date.formatted(.dateTime.month(.wide).year())).font(kit.font(22))
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 4), count: 7), spacing: 6) {
                ForEach(0..<7, id: \.self) { Text(wd[$0]).font(kit.font(13, true)).opacity(0.5) }
                ForEach(7..<(7 + lead + days), id: \.self) { i in
                    let n = i - 7 - lead + 1
                    Text(n > 0 ? "\(n)" : "")
                        .font(kit.font(15, n != today))
                        .frame(width: 28, height: 26)
                        .background(n == today ? kit.fg.opacity(0.25) : .clear, in: Circle())
                }
            }
            .frame(width: 236)
        }
    }
}

// MARK: - Widget view rendering all fourteen kinds
struct WidgetView: View {
    let item: WItem
    private var kit: StyleKit { StyleKit(style: item.style, tint: tints[min(max(item.tint, 0), tints.count - 1)]) }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { tl in
            content(tl.date).modifier(Chrome(kit: kit)).animation(.smooth, value: tl.date)
        }
    }

    private func time(_ d: Date, _ tz: TimeZone = .current) -> String {
        var f = Date.FormatStyle(locale: Locale(identifier: "de_DE")).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)
        f.timeZone = tz
        return d.formatted(f)
    }

    private func greeting(_ d: Date) -> String {
        let h = Calendar.current.component(.hour, from: d)
        let g = h < 5 ? "Gute Nacht" : h < 11 ? "Guten Morgen" : h < 17 ? "Guten Tag" : h < 22 ? "Guten Abend" : "Gute Nacht"
        return item.param.isEmpty ? g : "\(g), \(item.param)"
    }

    private func progress(_ d: Date, _ c: Calendar.Component) -> Double {
        guard let iv = Calendar.current.dateInterval(of: c, for: d) else { return 0 }
        return d.timeIntervalSince(iv.start) / iv.duration
    }

    @ViewBuilder private func content(_ d: Date) -> some View {
        switch item.kind {
        case .clock:
            Info(kit: kit, main: time(d), size: 120)
        case .analog:
            AnalogClock(date: d, kit: kit)
        case .date:
            Info(kit: kit, main: d.formatted(.dateTime.weekday(.wide)), sub: d.formatted(.dateTime.day().month(.wide).year()))
        case .calendar:
            MonthView(date: d, kit: kit)
        case .weather:
            if let w = Weather.shared.get(item.param) {
                let desc = Weather.describe(w.code)
                Info(kit: kit, sym: desc.0, main: "\(Int(w.temp.rounded()))°",
                     sub: "\(item.param) · \(desc.1)\nH \(Int(w.hi.rounded()))°  T \(Int(w.lo.rounded()))°", size: 52)
            } else {
                Info(kit: kit, sym: "cloud.sun", main: "–°", sub: item.param, size: 52)
            }
        case .world:
            let tz = TimeZone(identifier: item.param) ?? .current
            let city = (tz.identifier.split(separator: "/").last.map(String.init) ?? "").replacingOccurrences(of: "_", with: " ")
            Info(kit: kit, main: time(d, tz), sub: city, size: 56)
        case .countdown:
            let r = item.date.timeIntervalSince(d)
            if r <= 0 {
                Info(kit: kit, sym: "party.popper", main: "Jetzt!", sub: item.param, size: 52)
            } else if r < 86400 {
                let t = Int(r)
                Info(kit: kit, main: String(format: "%02d:%02d:%02d", t / 3600, t / 60 % 60, t % 60), sub: "bis \(item.param)", size: 56)
            } else {
                let n = Int(r / 86400)
                Info(kit: kit, main: n == 1 ? "1 Tag" : "\(n) Tage", sub: "bis \(item.param)", size: 56)
            }
        case .greeting:
            Info(kit: kit, main: greeting(d), size: 48)
        case .quote:
            let q = Sys.quotes[Int(d.timeIntervalSince1970 / 600) % Sys.quotes.count]
            Info(kit: kit, main: "„\(q.0)“", sub: "— \(q.1)", size: 28, width: 640)
        case .text:
            Info(kit: kit, main: item.param, size: 44, width: 760)
        case .battery:
            if let (p, ch) = Sys.battery() {
                let sym = ch ? "battery.100percent.bolt" : ["battery.0percent", "battery.25percent", "battery.50percent", "battery.75percent", "battery.100percent"][min(4, (p + 12) / 25)]
                Info(kit: kit, sym: sym, main: "\(p) %", sub: ch ? "Lädt" : "Batterie")
            } else {
                Info(kit: kit, sym: "powerplug", main: "Netz", sub: "Kein Akku")
            }
        case .system:
            HStack(spacing: 24) { Ring(kit: kit, value: Sys.cpu(), label: "CPU"); Ring(kit: kit, value: Sys.mem(), label: "RAM") }
        case .progress:
            HStack(spacing: 24) {
                Ring(kit: kit, value: progress(d, .day), label: "Tag")
                Ring(kit: kit, value: progress(d, .weekOfYear), label: "Woche")
                Ring(kit: kit, value: progress(d, .year), label: "Jahr")
            }
        case .moon:
            let m = Sys.moon(d)
            Info(kit: kit, sym: m.0, main: m.1, sub: "\(Int(m.2 * 100)) % beleuchtet", size: 34)
        }
    }
}
