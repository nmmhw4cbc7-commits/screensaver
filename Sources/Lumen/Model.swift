import SwiftUI
import ServiceManagement

// MARK: - Background catalogue
enum BG: String, CaseIterable, Identifiable, Codable {
    case aurora, mesh, pastel, spectrum, lava, midnight, stars, constellation, sonar, synth, waves, rain, bokeh, fireflies, dusk, photos
    var id: String { rawValue }
    var name: String {
        ["Aurora", "Farbfluss", "Pastell", "Spektrum", "Lava", "Mitternacht", "Sternenflug", "Netz", "Sonar", "Synthwave",
         "Ozean", "Regen", "Lichter", "Glühwürmchen", "Dämmerung", "Eigene Fotos"][BG.allCases.firstIndex(of: self)!]
    }
}

// MARK: - Clock face catalogue
enum Face: String, CaseIterable, Identifiable, Codable {
    case classic, stacked, flip, words, analog, chunky, matrix, segment, binary, rings, progress, split, editorial, pills, orbit, nixie
    var id: String { rawValue }
    var name: String {
        ["Klassisch", "Gestapelt", "Klappzahlen", "Worte", "Analog", "Analog Kräftig", "Punktmatrix", "Segment",
         "Binär", "Ringe", "Tagesbalken", "Geteilt", "Editorial", "Kapseln", "Orbit", "Röhre"][Face.allCases.firstIndex(of: self)!]
    }
}

// MARK: - Fonts and color palette
enum FontChoice: String, CaseIterable, Identifiable, Codable {
    case system, thin, heavy, rounded, serif, mono
    var id: String { rawValue }
    var name: String { ["Standard", "Dünn", "Fett", "Rund", "Serif", "Mono"][FontChoice.allCases.firstIndex(of: self)!] }
    func font(_ size: CGFloat) -> Font {
        switch self {
        case .system: return .system(size: size, weight: .medium)
        case .thin: return .system(size: size, weight: .ultraLight)
        case .heavy: return .system(size: size, weight: .black)
        case .rounded: return .system(size: size, weight: .semibold, design: .rounded)
        case .serif: return .system(size: size, weight: .regular, design: .serif)
        case .mono: return .system(size: size, weight: .medium, design: .monospaced)
        }
    }
}

let palette: [Color] = [
    .white, Color(red: 1, green: 0.9, blue: 0.75), Color(red: 0.55, green: 1, blue: 0.8), Color(red: 0.55, green: 0.8, blue: 1),
    Color(red: 0.78, green: 0.7, blue: 1), Color(red: 1, green: 0.6, blue: 0.76), Color(red: 1, green: 0.8, blue: 0.3),
    Color(red: 1, green: 0.5, blue: 0.35), Color(red: 0.75, green: 1, blue: 0.35), Color(white: 0.08),
]

// MARK: - Look: face + background + style
struct Look: Codable, Equatable {
    var bg: BG = .aurora
    var face: Face = .classic
    var font: FontChoice = .thin
    var color = 0
    var seconds = false
    var h24 = true
    var showDate = true
    var showWeather = false
    var city = "Berlin"
    var size = 1.0
    var speed = 1.0
    var hue = 0.0
    var dim = 0.0
}
