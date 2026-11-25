import SwiftUI

// MARK: - Time helpers
struct TimeParts {
    let h, m, s: Int
    let hh, mm, ss: String
    init(_ d: Date, _ h24: Bool) {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: d)
        h = c.hour ?? 0; m = c.minute ?? 0; s = c.second ?? 0
        let h12 = h % 12 == 0 ? 12 : h % 12
        hh = h24 ? String(format: "%02d", h) : "\(h12)"
        mm = String(format: "%02d", m)
        ss = String(format: "%02d", s)
    }
}

/// Monotonic local seconds, so hands never spin backwards when wrapping.
func localEpoch(_ d: Date) -> Double { floor(d.timeIntervalSince1970) + Double(TimeZone.current.secondsFromGMT(for: d)) }
