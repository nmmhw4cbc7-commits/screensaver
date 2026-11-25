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
