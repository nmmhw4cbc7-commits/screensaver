import SwiftUI
import ServiceManagement

// MARK: - Background catalogue
enum BG: String, CaseIterable, Identifiable, Codable {
    case aurora, mesh, spectrum, lava, stars, constellation, waves, rain, bokeh, fireflies, dusk, photos
    var id: String { rawValue }
    var name: String {
        ["Aurora", "Farbfluss", "Spektrum", "Lava", "Sternenflug", "Netz", "Ozean", "Regen", "Lichter", "Glühwürmchen", "Dämmerung", "Eigene Fotos"][BG.allCases.firstIndex(of: self)!]
    }
}

// MARK: - Widget catalogue
enum WKind: String, CaseIterable, Identifiable, Codable {
    case clock, analog, date, calendar, weather, world, countdown, greeting, quote, text, battery, system, progress, moon
    var id: String { rawValue }
    private var idx: Int { WKind.allCases.firstIndex(of: self)! }
    var name: String {
        ["Uhr", "Analoguhr", "Datum", "Kalender", "Wetter", "Weltzeit", "Countdown", "Begrüßung", "Zitat", "Eigener Text", "Batterie", "System", "Fortschritt", "Mondphase"][idx]
    }
    var symbol: String {
        ["clock", "deskclock", "calendar", "calendar.circle", "cloud.sun", "globe", "hourglass", "hand.wave", "quote.opening", "textformat", "battery.75percent", "cpu", "chart.pie", "moon.stars"][idx]
    }
    var defaultParam: String {
        switch self {
        case .weather: return "Berlin"
        case .world: return "America/New_York"
        case .countdown: return "Urlaub"
        case .text: return "Bleib fokussiert."
        case .greeting: return NSFullUserName().components(separatedBy: " ").first ?? ""
        default: return ""
        }
    }
}

// MARK: - Widget styles, tint palette and time zones
enum WStyle: String, CaseIterable, Identifiable, Codable {
    case glass, minimal, bold, mono, neon, serif, outline, card, color
    var id: String { rawValue }
    var name: String { ["Glas", "Minimal", "Kräftig", "Mono", "Neon", "Serif", "Kontur", "Karte", "Farbe"][WStyle.allCases.firstIndex(of: self)!] }
}

let tints: [Color] = [
    .white, Color(red: 1, green: 0.86, blue: 0.62), Color(red: 0.55, green: 1, blue: 0.8), Color(red: 0.55, green: 0.8, blue: 1),
    Color(red: 0.78, green: 0.7, blue: 1), Color(red: 1, green: 0.6, blue: 0.76), Color(red: 1, green: 0.8, blue: 0.3), Color(red: 1, green: 0.5, blue: 0.4),
]

let zones = ["Europe/Berlin", "Europe/London", "Europe/Moscow", "America/New_York", "America/Chicago", "America/Los_Angeles", "America/Sao_Paulo",
             "Asia/Dubai", "Asia/Kolkata", "Asia/Singapore", "Asia/Shanghai", "Asia/Tokyo", "Australia/Sydney", "Pacific/Auckland", "Africa/Johannesburg"]

// MARK: - Freely placed widget instance
struct WItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var kind: WKind
    var style: WStyle
    var tint: Int
    var x: Double
    var y: Double
    var scale: Double
    var param: String
    var date: Date

    init(_ kind: WKind, _ style: WStyle = .glass, _ x: Double = 0.5, _ y: Double = 0.5, scale: Double = 1, tint: Int = 0) {
        self.kind = kind; self.style = style; self.tint = tint; self.x = x; self.y = y; self.scale = scale
        param = kind.defaultParam
        date = Calendar.current.date(byAdding: .day, value: 30, to: .now)!
    }
}

// MARK: - Look combining background and widgets
struct Look: Codable, Equatable {
    var bg: BG
    var speed = 1.0
    var hue = 0.0
    var dim = 0.0
    var items: [WItem]
}
