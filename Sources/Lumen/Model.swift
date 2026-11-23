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
