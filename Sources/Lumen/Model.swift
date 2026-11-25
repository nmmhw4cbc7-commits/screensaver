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
