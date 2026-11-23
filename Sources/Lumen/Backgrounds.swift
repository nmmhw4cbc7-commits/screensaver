import SwiftUI

// MARK: - Background renderer with speed, hue and dimming
@inline(__always) func fract(_ x: Double) -> Double { x - floor(x) }
@inline(__always) func hash(_ n: Double) -> Double { fract(sin(n * 12.9898) * 43758.5453) }

struct BackgroundView: View {
    let bg: BG
    var speed = 1.0
    var hue = 0.0
    var dim = 0.0
    var fps: Double = 60

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / fps)) { tl in
            scene(tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 50_000) * speed)
        }
        .hueRotation(.degrees(hue * 360))
        .overlay(Color.black.opacity(dim))
        .background(.black)
        .clipped()
    }

    @ViewBuilder private func scene(_ t: Double) -> some View {
        switch bg {
        case .aurora: Blobs(t: t, lava: false)
        case .lava: Blobs(t: t, lava: true)
        case .mesh: Mesh(t: t)
        case .spectrum: Spectrum(t: t)
        case .stars: Stars(t: t)
        case .constellation: Constellation(t: t)
        case .waves: Waves(t: t)
        case .rain: Rain(t: t)
        case .bokeh: Particles(t: t, fireflies: false)
        case .fireflies: Particles(t: t, fireflies: true)
        case .dusk: Dusk(t: t)
        case .photos: Photos(t: t)
        }
    }
}

// MARK: - Aurora and lava blob backgrounds
private struct Blobs: View {
    let t: Double
    let lava: Bool
    private var cols: [Color] {
        lava ? [.init(red: 1, green: 0.35, blue: 0.1), .init(red: 1, green: 0.1, blue: 0.45), .init(red: 1, green: 0.65, blue: 0.1), .init(red: 0.7, green: 0.1, blue: 0.8)]
             : [.init(red: 0.1, green: 0.95, blue: 0.6), .init(red: 0.25, green: 0.35, blue: 1), .init(red: 0.75, green: 0.25, blue: 0.95), .init(red: 0.05, green: 0.65, blue: 0.95)]
    }
    var body: some View {
        GeometryReader { g in
            let s = g.size, m = min(s.width, s.height)
            ZStack {
                (lava ? Color(red: 0.12, green: 0.02, blue: 0.08) : Color(red: 0.01, green: 0.02, blue: 0.07))
                ForEach(0..<4, id: \.self) { i in blob(i, s, m) }
            }
            .blur(radius: m * (lava ? 0.07 : 0.12))
            .frame(width: s.width, height: s.height)
        }
    }

    private func blob(_ i: Int, _ s: CGSize, _ m: CGFloat) -> some View {
        let f = Double(i)
        let w: CGFloat = lava ? m * (0.35 + 0.1 * sin(t * 0.2 + f)) : m * (1.2 + 0.3 * sin(t * 0.11 + f))
        let h: CGFloat = lava ? w * (1 + 0.25 * sin(t * 0.3 + f * 2)) : m * 0.45
        let x: CGFloat = s.width * (lava ? 0.3 : 0.35) * sin(t * 0.07 * (1 + f * 0.3) + f * 1.7)
        let y: CGFloat = s.height * (lava ? 0.4 : 0.3) * cos(t * (lava ? 0.09 : 0.05) * (1 + f * 0.2) + f * 2.3)
        let deg: Double = 20 * sin(t * 0.05 + f * 2)
        return Ellipse().fill(cols[i].opacity(lava ? 0.85 : 0.6))
            .frame(width: w, height: h)
            .rotationEffect(.degrees(deg))
            .offset(x: x, y: y)
            .blendMode(.screen)
    }
}
