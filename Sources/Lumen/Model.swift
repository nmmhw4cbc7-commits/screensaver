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

// MARK: - Widget kinds
enum WKind: String, CaseIterable, Codable {
    case clock, date, battery, verse
    var name: String {
        switch self {
        case .clock: "Uhr"
        case .date: "Datum"
        case .battery: "Batterie"
        case .verse: "Bibelvers"
        }
    }
    var symbol: String {
        switch self {
        case .clock: "clock"
        case .date: "calendar"
        case .battery: "battery.75percent"
        case .verse: "book.closed"
        }
    }
}

// MARK: - Widget styles
enum WStyle: String, CaseIterable, Codable {
    case glass, minimal, bold, mono
    var name: String {
        switch self {
        case .glass: "Glas"
        case .minimal: "Minimal"
        case .bold: "Kräftig"
        case .mono: "Mono"
        }
    }
}

// MARK: - Nine-point widget placement grid
enum Pos: String, CaseIterable, Codable, Identifiable {
    case topLeading, top, topTrailing, leading, center, trailing, bottomLeading, bottom, bottomTrailing
    var id: String { rawValue }
    var alignment: Alignment {
        [.topLeading, .top, .topTrailing, .leading, .center, .trailing, .bottomLeading, .bottom, .bottomTrailing][Pos.allCases.firstIndex(of: self)!]
    }
    var hAlign: HorizontalAlignment {
        switch alignment.horizontal {
        case .leading: .leading
        case .trailing: .trailing
        default: .center
        }
    }
}

// MARK: - Widget configuration with defaults
struct WConf: Codable, Identifiable, Hashable {
    var kind: WKind
    var enabled: Bool
    var style: WStyle
    var pos: Pos
    var id: WKind { kind }

    static let defaults: [WConf] = [
        .init(kind: .clock, enabled: true, style: .minimal, pos: .center),
        .init(kind: .date, enabled: true, style: .minimal, pos: .center),
        .init(kind: .battery, enabled: false, style: .glass, pos: .topTrailing),
        .init(kind: .verse, enabled: true, style: .glass, pos: .bottomLeading),
    ]
}

// MARK: - Persistent settings store
final class Store: ObservableObject {
    static let shared = Store()
    private let d = UserDefaults.standard

    @Published var bg: BG { didSet { d.set(bg.rawValue, forKey: "bg") } }
    @Published var widgets: [WConf] { didSet { d.set(try? JSONEncoder().encode(widgets), forKey: "widgets") } }
    @Published var idleMinutes: Int { didSet { d.set(idleMinutes, forKey: "idle") } }
    @Published var onboarded: Bool { didSet { d.set(onboarded, forKey: "onboarded") } }

    init() {
        bg = BG(rawValue: d.string(forKey: "bg") ?? "") ?? .aurora
        widgets = d.data(forKey: "widgets").flatMap { try? JSONDecoder().decode([WConf].self, from: $0) } ?? WConf.defaults
        idleMinutes = d.object(forKey: "idle") as? Int ?? 5
        onboarded = d.bool(forKey: "onboarded")
    }
}
