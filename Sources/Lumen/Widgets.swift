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
