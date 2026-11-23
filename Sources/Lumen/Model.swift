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

// MARK: - Curated design presets
struct Preset: Identifiable {
    let name: String
    let look: Look
    var id: String { name }
}

let presets: [Preset] = [
    Preset(name: "Nordlicht", look: Look(bg: .aurora, items: [WItem(.clock, .minimal, 0.5, 0.44, scale: 1.3), WItem(.date, .minimal, 0.5, 0.63)])),
    Preset(name: "Studio", look: Look(bg: .mesh, items: [WItem(.analog, .glass, 0.27, 0.5, scale: 1.3), WItem(.weather, .glass, 0.72, 0.32), WItem(.calendar, .glass, 0.72, 0.66)])),
    Preset(name: "Neon", look: Look(bg: .constellation, items: [WItem(.clock, .neon, 0.5, 0.42, scale: 1.4, tint: 5), WItem(.greeting, .neon, 0.5, 0.65, tint: 3)])),
    Preset(name: "Zen", look: Look(bg: .waves, items: [WItem(.clock, .serif, 0.5, 0.34), WItem(.quote, .serif, 0.5, 0.6)])),
    Preset(name: "Dashboard", look: Look(bg: .spectrum, dim: 0.35, items: [
        WItem(.clock, .card, 0.2, 0.27, scale: 0.75, tint: 3), WItem(.weather, .card, 0.5, 0.27, scale: 1.2, tint: 6), WItem(.world, .card, 0.8, 0.27, scale: 1.2, tint: 2),
        WItem(.system, .card, 0.2, 0.73, scale: 1.2, tint: 5), WItem(.progress, .card, 0.5, 0.73, scale: 1.2, tint: 4), WItem(.battery, .card, 0.8, 0.73, scale: 1.2, tint: 2)])),
    Preset(name: "Terminal", look: Look(bg: .rain, items: [WItem(.clock, .mono, 0.5, 0.42, tint: 2), WItem(.countdown, .mono, 0.5, 0.64, tint: 2)])),
    Preset(name: "Kosmos", look: Look(bg: .stars, items: [WItem(.clock, .bold, 0.2, 0.82), WItem(.moon, .outline, 0.84, 0.16, tint: 4)])),
    Preset(name: "Lagerfeuer", look: Look(bg: .fireflies, items: [WItem(.clock, .color, 0.5, 0.45, scale: 0.9, tint: 1), WItem(.date, .minimal, 0.5, 0.67, tint: 1)])),
]

// MARK: - Persistent settings store
final class Store: ObservableObject {
    static let shared = Store()
    private let d = UserDefaults.standard

    @Published var look: Look { didSet { d.set(try? JSONEncoder().encode(look), forKey: "look") } }
    @Published var idleMinutes: Int { didSet { d.set(idleMinutes, forKey: "idle") } }
    @Published var displaySleep: Int { didSet { d.set(displaySleep, forKey: "displaySleep") } }
    @Published var skipVideo: Bool { didSet { d.set(skipVideo, forKey: "skipVideo") } }
    @Published var photoFolder: String { didSet { d.set(photoFolder, forKey: "photos") } }
    @Published var onboarded: Bool { didSet { d.set(onboarded, forKey: "onboarded2") } }

    init() {
        look = d.data(forKey: "look").flatMap { try? JSONDecoder().decode(Look.self, from: $0) } ?? presets[0].look
        idleMinutes = d.object(forKey: "idle") as? Int ?? 5
        displaySleep = d.object(forKey: "displaySleep") as? Int ?? 0
        skipVideo = d.object(forKey: "skipVideo") as? Bool ?? true
        photoFolder = d.string(forKey: "photos") ?? ""
        onboarded = d.bool(forKey: "onboarded2")
    }

    // MARK: - Launch at login via SMAppService
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            try? newValue ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
            objectWillChange.send()
        }
    }
}
