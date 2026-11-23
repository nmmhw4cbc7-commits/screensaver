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
