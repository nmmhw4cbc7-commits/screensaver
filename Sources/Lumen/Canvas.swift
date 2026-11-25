import SwiftUI

// MARK: - Saver canvas: background + clock with burn-in drift
struct SaverCanvas: View {
    let look: Look
    var fps: Double = 60

    var body: some View {
        GeometryReader { g in
            let k = g.size.width / 1440
            ZStack {
                BackgroundView(bg: look.bg, speed: look.speed, hue: look.hue, dim: look.dim, fps: fps)
                TimelineView(.periodic(from: .now, by: 1)) { tl in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    ClockView(look: look, date: tl.date)
                        .frame(width: 1440, height: 900)
                        .offset(x: 16 * sin(t / 40), y: 12 * cos(t / 53))
                        .scaleEffect(k)
                        .frame(width: g.size.width, height: g.size.height)
                }
            }
        }
    }
}
