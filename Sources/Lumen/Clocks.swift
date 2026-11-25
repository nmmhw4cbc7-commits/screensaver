import SwiftUI

// MARK: - Time helpers
struct TimeParts {
    let h, m, s: Int
    let hh, mm, ss: String
    init(_ d: Date, _ h24: Bool) {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: d)
        h = c.hour ?? 0; m = c.minute ?? 0; s = c.second ?? 0
        let h12 = h % 12 == 0 ? 12 : h % 12
        hh = h24 ? String(format: "%02d", h) : "\(h12)"
        mm = String(format: "%02d", m)
        ss = String(format: "%02d", s)
    }
}

/// Monotonic local seconds, so hands never spin backwards when wrapping.
func localEpoch(_ d: Date) -> Double { floor(d.timeIntervalSince1970) + Double(TimeZone.current.secondsFromGMT(for: d)) }

// MARK: - Weather via Open-Meteo (no API key)
final class Weather {
    static let shared = Weather()
    struct Now { var temp: Double; var code: Int }
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
              let f = try? await json("https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current=temperature_2m,weather_code&timezone=auto"),
              let cur = f["current"] as? [String: Any]
        else { fetched[city] = Date().addingTimeInterval(-1700); return }
        let n = Now(temp: cur["temperature_2m"] as? Double ?? 0, code: cur["weather_code"] as? Int ?? 0)
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

// MARK: - Clock view dispatching all sixteen faces
struct ClockView: View {
    let look: Look
    let date: Date
    private var c: Color { palette[min(max(look.color, 0), palette.count - 1)] }
    private func f(_ s: CGFloat) -> Font { look.font.font(s) }
    private func digits(_ t: TimeParts) -> String { t.hh + ":" + t.mm + (look.seconds ? ":" + t.ss : "") }

    var body: some View {
        VStack(spacing: 40) {
            face(TimeParts(date, look.h24))
            info
        }
        .foregroundStyle(c)
        .scaleEffect(look.size)
        .animation(.smooth(duration: 0.5), value: date)
    }

    @ViewBuilder private var info: some View {
        if look.showDate || look.showWeather {
            HStack(spacing: 30) {
                if look.showDate { Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide))) }
                if look.showWeather, let w = Weather.shared.get(look.city) {
                    let d = Weather.describe(w.code)
                    Label("\(Int(w.temp.rounded()))° · \(d.1)", systemImage: d.0)
                }
            }
            .font(f(40))
            .opacity(0.8)
        }
    }

    @ViewBuilder private func face(_ t: TimeParts) -> some View {
        switch look.face {
        case .classic:
            Text(digits(t)).font(f(240)).monospacedDigit().contentTransition(.numericText())
        case .stacked:
            VStack(spacing: -80) { Text(t.hh); Text(t.mm).opacity(0.55) }
                .font(f(310)).monospacedDigit().contentTransition(.numericText())
        case .flip:
            HStack(spacing: 18) {
                FlipCard(text: t.hh, font: f(200))
                FlipCard(text: t.mm, font: f(200))
                if look.seconds { FlipCard(text: t.ss, font: f(200)).opacity(0.7) }
            }
        case .words:
            Text("Es ist\n" + Self.words(t.h, t.m)).font(f(104))
                .multilineTextAlignment(.leading).frame(width: 1150, alignment: .leading)
        case .analog:
            Analog(date: date, bold: false, seconds: look.seconds)
        case .chunky:
            Analog(date: date, bold: true, seconds: look.seconds)
        case .matrix:
            DotDigits(text: digits(t), color: c).shadow(color: c.opacity(0.5), radius: 14)
        case .segment:
            SegDigits(text: digits(t), color: c).shadow(color: c.opacity(0.5), radius: 14)
        case .binary:
            BinaryClock(t: t, seconds: look.seconds, color: c)
        case .rings:
            Rings(t: t, seconds: look.seconds, color: c, font: f(112))
        case .progress:
            let p = Double(t.h * 3600 + t.m * 60 + t.s) / 86400
            VStack(spacing: 30) {
                Text(t.hh + ":" + t.mm).font(f(210)).monospacedDigit().contentTransition(.numericText())
                ZStack(alignment: .leading) {
                    Capsule().fill(c.opacity(0.15))
                    Capsule().fill(c).frame(width: 900 * p)
                }
                .frame(width: 900, height: 14)
                Text("\(Int(p * 100)) % des Tages").font(f(34)).opacity(0.7)
            }
        case .split:
            HStack(alignment: .center, spacing: 34) {
                Text(t.hh).font(f(360))
                VStack(alignment: .leading, spacing: 0) {
                    Text(t.mm).font(f(180))
                    Text(date.formatted(.dateTime.weekday(.wide))).font(f(46)).opacity(0.65)
                }
            }
            .monospacedDigit().contentTransition(.numericText())
        case .editorial:
            VStack(spacing: 20) {
                Text(date.formatted(.dateTime.weekday(.wide)).uppercased()).font(f(28)).tracking(14).opacity(0.75)
                Text(t.hh + ":" + t.mm).font(f(250)).italic().monospacedDigit().contentTransition(.numericText())
                Rectangle().fill(c.opacity(0.6)).frame(width: 420, height: 2)
                Text(date.formatted(.dateTime.day().month(.wide).year())).font(f(32)).opacity(0.75)
            }
        case .pills:
            HStack(spacing: 14) {
                ForEach(Array(digits(t).enumerated()), id: \.offset) { _, ch in
                    if ch == ":" {
                        VStack(spacing: 40) { Circle().frame(width: 18, height: 18); Circle().frame(width: 18, height: 18) }.opacity(0.6)
                    } else {
                        Text(String(ch)).font(f(150)).monospacedDigit().contentTransition(.numericText())
                            .frame(width: 150, height: 240)
                            .background(.ultraThinMaterial, in: Capsule())
                            .environment(\.colorScheme, .dark)
                    }
                }
            }
        case .orbit:
            Orbit(date: date, t: t, color: c, font: f)
        case .nixie:
            let glow = look.color == 0 ? Color(red: 1, green: 0.55, blue: 0.2) : c
            HStack(spacing: 14) {
                ForEach(Array(digits(t).enumerated()), id: \.offset) { _, ch in
                    if ch == ":" {
                        VStack(spacing: 50) { Circle().frame(width: 14, height: 14); Circle().frame(width: 14, height: 14) }
                            .foregroundStyle(glow).shadow(color: glow, radius: 10)
                    } else {
                        NixieTube(ch: ch, color: glow)
                    }
                }
            }
        }
    }

    // MARK: - German word clock
    static func words(_ h: Int, _ m: Int) -> String {
        let n = ["zwölf", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn", "elf"]
        var five = Int((Double(m) / 5).rounded())
        var hr = h
        if five == 12 { five = 0; hr += 1 }
        let cur = n[hr % 12], nxt = n[(hr + 1) % 12]
        if five == 0 { return (cur == "eins" ? "ein" : cur) + " Uhr" }
        let phrases = ["", "fünf nach C", "zehn nach C", "viertel nach C", "zwanzig nach C", "fünf vor halb N", "halb N",
                       "fünf nach halb N", "zwanzig vor N", "viertel vor N", "zehn vor N", "fünf vor N"]
        return phrases[five].replacingOccurrences(of: "C", with: cur).replacingOccurrences(of: "N", with: nxt)
    }
}

// MARK: - Flip cards
struct FlipCard: View {
    let text: String
    let font: Font
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.black.opacity(0.55))
            Text(text).font(font).monospacedDigit().contentTransition(.numericText()).fixedSize()
            Rectangle().fill(.black.opacity(0.6)).frame(height: 5)
        }
        .frame(width: 300, height: 280)
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(.white.opacity(0.08)))
    }
}

// MARK: - Analog faces
struct Analog: View {
    let date: Date
    let bold: Bool
    let seconds: Bool
    var body: some View {
        let e = localEpoch(date)
        let r: CGFloat = 290
        ZStack {
            if bold { Circle().opacity(0.08) }
            ForEach(0..<(bold ? 12 : 60), id: \.self) { i in tick(i, r) }
            hand(e / 120, r * 0.5, bold ? 24 : 7)
            hand(e / 10, r * 0.78, bold ? 16 : 5)
            if seconds { hand(e * 6, r * 0.86, 2).foregroundStyle(.orange) }
            Circle().frame(width: bold ? 38 : 16, height: bold ? 38 : 16)
        }
        .frame(width: r * 2, height: r * 2)
    }

    private func tick(_ i: Int, _ r: CGFloat) -> some View {
        let major = bold || i % 5 == 0
        return Group {
            if bold { Circle().frame(width: 18, height: 18) } else { Capsule().frame(width: major ? 4 : 2, height: major ? 28 : 12) }
        }
        .opacity(major ? 0.9 : 0.35)
        .offset(y: -(r - (bold ? 36 : 22)))
        .rotationEffect(.degrees(Double(i) * (bold ? 30 : 6)))
    }

    private func hand(_ deg: Double, _ len: CGFloat, _ w: CGFloat) -> some View {
        Capsule().frame(width: w, height: len).offset(y: -len / 2 + w / 2).rotationEffect(.degrees(deg))
    }
}

// MARK: - Dot-matrix digits
struct DotDigits: View {
    let text: String
    let color: Color
    var dot: CGFloat = 24
    static let glyphs: [Character: [Int]] = [
        "0": [14, 17, 19, 21, 25, 17, 14], "1": [4, 12, 4, 4, 4, 4, 14], "2": [14, 17, 1, 2, 4, 8, 31],
        "3": [31, 2, 4, 2, 1, 17, 14], "4": [2, 6, 10, 18, 31, 2, 2], "5": [31, 16, 30, 1, 1, 17, 14],
        "6": [6, 8, 16, 30, 17, 17, 14], "7": [31, 1, 2, 4, 8, 8, 8], "8": [14, 17, 17, 14, 17, 17, 14],
        "9": [14, 17, 17, 15, 1, 2, 12],
    ]
    var body: some View {
        let step = dot * 1.35
        let cols = text.reduce(0) { $0 + ($1 == ":" ? 1 : 5) + 1 } - 1
        Canvas { ctx, _ in
            var x: CGFloat = 0
            for ch in text {
                let w = ch == ":" ? 1 : 5
                let rows = Self.glyphs[ch] ?? [0, 0, 1, 0, 1, 0, 0]
                for r in 0..<7 {
                    for col in 0..<w {
                        let on = ch == ":" ? rows[r] == 1 : (rows[r] >> (4 - col)) & 1 == 1
                        let rect = CGRect(x: x + CGFloat(col) * step, y: CGFloat(r) * step, width: dot, height: dot)
                        ctx.fill(Path(ellipseIn: rect), with: .color(color.opacity(on ? 1 : 0.08)))
                    }
                }
                x += CGFloat(w + 1) * step
            }
        }
        .frame(width: CGFloat(cols) * step - (step - dot), height: 7 * step - (step - dot))
    }
}

// MARK: - Seven-segment digits
struct SegDigits: View {
    let text: String
    let color: Color
    static let map: [Character: Int] = ["0": 0x3F, "1": 0x06, "2": 0x5B, "3": 0x4F, "4": 0x66, "5": 0x6D, "6": 0x7D, "7": 0x07, "8": 0x7F, "9": 0x6F]
    var body: some View {
        let w: CGFloat = 124, h: CGFloat = 230, th: CGFloat = 22, gap: CGFloat = 36, colonW: CGFloat = 40
        let total = text.reduce(CGFloat(0)) { $0 + ($1 == ":" ? colonW : w) + gap } - gap
        Canvas { ctx, _ in
            var x: CGFloat = 0
            for ch in text {
                if ch == ":" {
                    for y in [h * 0.3, h * 0.7] {
                        ctx.fill(Path(ellipseIn: CGRect(x: x + colonW / 2 - th / 2, y: y - th / 2, width: th, height: th)), with: .color(color))
                    }
                    x += colonW + gap
                    continue
                }
                let bits = Self.map[ch] ?? 0
                let v = h / 2 - th * 1.5
                let segs = [
                    CGRect(x: x + th, y: 0, width: w - 2 * th, height: th),
                    CGRect(x: x + w - th, y: th, width: th, height: v),
                    CGRect(x: x + w - th, y: h / 2 + th / 2, width: th, height: v),
                    CGRect(x: x + th, y: h - th, width: w - 2 * th, height: th),
                    CGRect(x: x, y: h / 2 + th / 2, width: th, height: v),
                    CGRect(x: x, y: th, width: th, height: v),
                    CGRect(x: x + th, y: h / 2 - th / 2, width: w - 2 * th, height: th),
                ]
                for (i, r) in segs.enumerated() {
                    let on = (bits >> i) & 1 == 1
                    ctx.fill(Path(roundedRect: r.insetBy(dx: 2, dy: 2), cornerRadius: th / 2), with: .color(color.opacity(on ? 1 : 0.07)))
                }
                x += w + gap
            }
        }
        .frame(width: total, height: h)
        .transformEffect(CGAffineTransform(a: 1, b: 0, c: -0.08, d: 1, tx: h * 0.04, ty: 0))
    }
}
