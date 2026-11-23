import SwiftUI

// MARK: - Background renderer with animation timeline
@inline(__always) func fract(_ x: Double) -> Double { x - floor(x) }
@inline(__always) func hash(_ n: Double) -> Double { fract(sin(n * 12.9898) * 43758.5453) }

struct BackgroundView: View {
    let bg: BG
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 100_000)
            Group {
                switch bg {
                case .aurora: Aurora(t: t)
                case .mesh: Mesh(t: t)
                case .stars: Stars(t: t)
                case .waves: Waves(t: t)
                case .bokeh: Bokeh(t: t)
                }
            }
        }
        .background(.black)
        .clipped()
    }
}

// MARK: - Aurora background
private struct Aurora: View {
    let t: Double
    let cols: [Color] = [
        .init(red: 0.1, green: 0.95, blue: 0.6), .init(red: 0.25, green: 0.35, blue: 1),
        .init(red: 0.75, green: 0.25, blue: 0.95), .init(red: 0.05, green: 0.65, blue: 0.95),
    ]
    var body: some View {
        GeometryReader { g in
            let s = g.size, m = min(s.width, s.height)
            ZStack {
                Color(red: 0.01, green: 0.02, blue: 0.07)
                ForEach(0..<cols.count, id: \.self) { i in blob(i, s, m) }
            }
            .blur(radius: m * 0.12)
            .frame(width: s.width, height: s.height)
        }
    }

    private func blob(_ i: Int, _ s: CGSize, _ m: CGFloat) -> some View {
        let f = Double(i)
        let w: CGFloat = m * (1.2 + 0.3 * sin(t * 0.11 + f))
        let x: CGFloat = s.width * 0.35 * sin(t * 0.07 * (1 + f * 0.3) + f * 1.7)
        let y: CGFloat = s.height * 0.3 * cos(t * 0.05 * (1 + f * 0.2) + f * 2.3)
        let deg: Double = 20 * sin(t * 0.05 + f * 2)
        return Ellipse().fill(cols[i].opacity(0.6))
            .frame(width: w, height: m * 0.45)
            .rotationEffect(.degrees(deg))
            .offset(x: x, y: y)
            .blendMode(.screen)
    }
}

// MARK: - Flowing mesh gradient background
private struct Mesh: View {
    let t: Double
    var body: some View {
        let p = { (a: Double, b: Double) -> SIMD2<Float> in [Float(a), Float(b)] }
        MeshGradient(width: 3, height: 3, points: [
            p(0, 0), p(0.5 + 0.2 * sin(t * 0.21), 0), p(1, 0),
            p(0, 0.5 + 0.2 * cos(t * 0.17)), p(0.5 + 0.25 * sin(t * 0.3), 0.5 + 0.25 * cos(t * 0.23)), p(1, 0.5 + 0.2 * sin(t * 0.19)),
            p(0, 1), p(0.5 + 0.2 * cos(t * 0.25), 1), p(1, 1),
        ], colors: (0..<9).map { i in
            let f = Double(i)
            return Color(hue: fract(0.55 + f * 0.045 + t * 0.008 + 0.05 * sin(t * 0.1 + f)),
                         saturation: 0.75, brightness: 0.45 + 0.35 * hash(f))
        })
    }
}
