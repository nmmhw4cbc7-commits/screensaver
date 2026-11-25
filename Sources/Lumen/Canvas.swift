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

// MARK: - Live thumbnails
struct LookThumb: View {
    let look: Look
    var width: CGFloat = 240
    var fps: Double = 15
    var body: some View {
        SaverCanvas(look: look, fps: fps)
            .frame(width: width, height: width * 10 / 16)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)
    }
}

struct FaceThumb: View {
    let look: Look
    let face: Face
    var width: CGFloat = 180
    var body: some View {
        var l = look
        l.face = face
        l.showDate = false
        l.showWeather = false
        l.size = 1
        return TimelineView(.periodic(from: .now, by: 1)) { tl in
            ClockView(look: l, date: tl.date)
                .frame(width: 1440, height: 900)
                .scaleEffect(width / 1440 * 1.45)
                .frame(width: width, height: width * 10 / 16)
        }
        .background(Color(white: 0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
