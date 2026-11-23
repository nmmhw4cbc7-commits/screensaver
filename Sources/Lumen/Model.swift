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
