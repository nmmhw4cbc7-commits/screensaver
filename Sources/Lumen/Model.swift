import SwiftUI
import ServiceManagement

// MARK: - Animated background catalogue
enum BG: String, CaseIterable, Identifiable, Codable {
    case aurora, mesh, stars, waves, bokeh
    var id: String { rawValue }
    var name: String {
        switch self {
        case .aurora: "Aurora"
        case .mesh: "Farbfluss"
        case .stars: "Sternenflug"
        case .waves: "Ozean"
        case .bokeh: "Lichter"
        }
    }
}
