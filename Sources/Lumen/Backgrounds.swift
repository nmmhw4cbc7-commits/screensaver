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

// MARK: - Mesh gradient and spectrum backgrounds
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
            let h = fract(0.55 + f * 0.045 + t * 0.008 + 0.05 * sin(t * 0.1 + f))
            return Color(hue: h, saturation: 0.75, brightness: 0.45 + 0.35 * hash(f))
        })
    }
}

private struct Spectrum: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let m = max(g.size.width, g.size.height)
            ZStack {
                AngularGradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .pink, .red], center: .center, angle: .degrees(t * 8))
                    .frame(width: m * 1.6, height: m * 1.6)
                    .blur(radius: m * 0.08)
                RadialGradient(colors: [.black.opacity(0.1), .black.opacity(0.85)], center: .center, startRadius: m * 0.05, endRadius: m * 0.6)
            }
            .frame(width: g.size.width, height: g.size.height)
        }
    }
}

// MARK: - Starfield and constellation network
private struct Stars: View {
    let t: Double
    var body: some View {
        Canvas { c, s in
            c.fill(Path(CGRect(origin: .zero, size: s)), with: .radialGradient(
                Gradient(colors: [Color(red: 0.08, green: 0.05, blue: 0.2), .black]),
                center: CGPoint(x: s.width / 2, y: s.height / 2), startRadius: 0, endRadius: max(s.width, s.height) * 0.7))
            let cx = s.width / 2, cy = s.height / 2
            for i in 0..<500 {
                let f = Double(i)
                let depth = fract(hash(f + 7) - t * 0.06)
                let scale = 1 / (depth * 2.5 + 0.12)
                let x = cx + (hash(f) * 2 - 1) * cx * 0.45 * scale
                let y = cy + (hash(f + 3) * 2 - 1) * cy * 0.45 * scale
                guard x > -5, x < s.width + 5, y > -5, y < s.height + 5 else { continue }
                let r = (1 - depth) * 2.6 + 0.4
                c.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                       with: .color(.white.opacity(min(1, (1 - depth) * 1.4))))
            }
        }
    }
}

private struct Constellation: View {
    let t: Double
    var body: some View {
        Canvas { c, s in
            c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.03, green: 0.03, blue: 0.12), Color(red: 0.08, green: 0.02, blue: 0.16)]),
                startPoint: .zero, endPoint: CGPoint(x: s.width, y: s.height)))
            let pts: [CGPoint] = (0..<90).map { i in
                let f = Double(i)
                let x = fract(hash(f) + t * 0.006 * (hash(f + 1) * 2 - 1))
                let y = fract(hash(f + 2) + t * 0.006 * (hash(f + 3) * 2 - 1))
                return CGPoint(x: x * s.width, y: y * s.height)
            }
            let maxD = min(s.width, s.height) * 0.17
            for i in 0..<pts.count {
                for j in (i + 1)..<pts.count {
                    let d = hypot(pts[i].x - pts[j].x, pts[i].y - pts[j].y)
                    guard d < maxD else { continue }
                    var p = Path(); p.move(to: pts[i]); p.addLine(to: pts[j])
                    c.stroke(p, with: .color(Color(red: 0.5, green: 0.8, blue: 1).opacity(Double(1 - d / maxD) * 0.45)), lineWidth: 1)
                }
                c.fill(Path(ellipseIn: CGRect(x: pts[i].x - 2.5, y: pts[i].y - 2.5, width: 5, height: 5)), with: .color(.white.opacity(0.85)))
            }
        }
    }
}

// MARK: - Ocean waves and rain
private struct Waves: View {
    let t: Double
    var body: some View {
        Canvas { c, s in
            c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.02, green: 0.05, blue: 0.15), Color(red: 0.0, green: 0.2, blue: 0.3)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height)))
            for i in 0..<7 {
                let f = Double(i)
                let base = s.height * (0.4 + f * 0.085)
                var p = Path()
                p.move(to: CGPoint(x: 0, y: s.height))
                for x in stride(from: 0.0, through: s.width + 8, by: 8) {
                    let u = x / s.width
                    let y = base + sin(u * .pi * 2 * (1 + f * 0.3) + t * (0.25 + f * 0.07) + f) * s.height * 0.05
                        + sin(u * 9 - t * 0.6 + f * 2) * s.height * 0.012
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                p.addLine(to: CGPoint(x: s.width, y: s.height))
                p.closeSubpath()
                c.fill(p, with: .color(Color(hue: 0.52 + f * 0.025, saturation: 0.75, brightness: 0.45 + f * 0.07).opacity(0.38)))
            }
        }
    }
}

private struct Rain: View {
    let t: Double
    var body: some View {
        Canvas { c, s in
            c.fill(Path(CGRect(origin: .zero, size: s)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.02, green: 0.04, blue: 0.08), Color(red: 0.05, green: 0.12, blue: 0.16)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: s.height)))
            for i in 0..<320 {
                let f = Double(i)
                let v = 0.5 + hash(f + 1)
                let len = (18 + 40 * v) * s.height / 900
                let y = fract(hash(f + 2) + t * 0.35 * v) * (s.height + len * 2) - len
                let x = s.width * hash(f)
                var p = Path(); p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x - len * 0.12, y: y + len))
                c.stroke(p, with: .color(Color(red: 0.6, green: 0.85, blue: 1).opacity(0.1 + 0.25 * (v - 0.5))), lineWidth: v)
            }
        }
    }
}

// MARK: - Bokeh lights and fireflies
private struct Particles: View {
    let t: Double
    let fireflies: Bool
    var body: some View {
        GeometryReader { g in
            let s = g.size, m = min(s.width, s.height)
            ZStack {
                LinearGradient(colors: fireflies ? [Color(red: 0.02, green: 0.06, blue: 0.05), Color(red: 0.01, green: 0.02, blue: 0.03)]
                                                 : [Color(red: 0.12, green: 0.04, blue: 0.1), Color(red: 0.02, green: 0.01, blue: 0.05)],
                               startPoint: .top, endPoint: .bottom)
                ForEach(0..<(fireflies ? 60 : 34), id: \.self) { i in dot(Double(i), s, m) }
            }
        }
    }

    private func dot(_ f: Double, _ s: CGSize, _ m: CGFloat) -> some View {
        let d: CGFloat = fireflies ? m * (0.006 + 0.01 * hash(f + 1)) : m * (0.04 + 0.16 * hash(f + 1))
        let hue = fireflies ? 0.16 + 0.06 * hash(f + 4) : 0.02 + 0.13 * hash(f + 4)
        let glow = fireflies ? 0.5 + 0.5 * sin(t * (1 + hash(f + 9)) + f) : 0.35 + 0.3 * hash(f + 6)
        let x: CGFloat
        let y: CGFloat
        if fireflies {
            x = s.width * fract(hash(f + 3) + 0.06 * sin(t * 0.13 + f))
            y = s.height * fract(hash(f + 2) + 0.05 * cos(t * 0.11 + f * 1.3))
        } else {
            let r = fract(hash(f + 2) + t * (0.008 + 0.02 * hash(f + 5)))
            x = s.width * hash(f + 3) + 40 * sin(t * 0.2 + f)
            y = (s.height + d * 2) * (1 - r) - d
        }
        let col = Color(hue: hue, saturation: fireflies ? 0.8 : 0.7, brightness: 1)
        return Circle().fill(col.opacity(glow))
            .frame(width: d, height: d)
            .blur(radius: fireflies ? d * 0.3 : d * (0.05 + 0.25 * hash(f + 8)))
            .shadow(color: fireflies ? col.opacity(glow) : .clear, radius: d * 1.5)
            .position(x: x, y: y)
            .blendMode(.screen)
    }
}

// MARK: - Dusk scene
private struct Dusk: View {
    let t: Double
    var body: some View {
        GeometryReader { g in
            let s = g.size
            let k = 0.5 + 0.5 * sin(t * 0.02)
            ZStack {
                LinearGradient(colors: [Color(hue: 0.64, saturation: 0.6, brightness: 0.18 + 0.2 * k),
                                        Color(hue: 0.93, saturation: 0.5, brightness: 0.45 + 0.3 * k),
                                        Color(hue: 0.07, saturation: 0.8, brightness: 0.95)], startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hue: 0.1, saturation: 0.55, brightness: 1))
                    .frame(width: s.height * 0.22, height: s.height * 0.22)
                    .shadow(color: .orange, radius: s.height * 0.1)
                    .position(x: s.width * 0.5, y: s.height * (0.74 - 0.12 * k))
                LinearGradient(colors: [Color(hue: 0.75, saturation: 0.5, brightness: 0.16), .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: s.height * 0.26)
                    .position(x: s.width / 2, y: s.height * 0.87)
            }
        }
    }
}

// MARK: - Own photos with Ken Burns crossfade
final class PhotoLib {
    static let shared = PhotoLib()
    private var folder = ""
    private var urls: [URL] = []
    private var cache: [Int: NSImage] = [:]

    var count: Int { refresh(); return urls.count }

    private func refresh() {
        let f = Store.shared.photoFolder
        guard f != folder else { return }
        folder = f; cache = [:]
        let exts = ["jpg", "jpeg", "png", "heic", "tiff", "webp"]
        urls = ((try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: f), includingPropertiesForKeys: nil)) ?? [])
            .filter { exts.contains($0.pathExtension.lowercased()) }
            .sorted { $0.path < $1.path }
    }

    func image(_ i: Int) -> NSImage? {
        refresh()
        guard !urls.isEmpty else { return nil }
        let k = i % urls.count
        if let im = cache[k] { return im }
        if cache.count > 3 { cache = [:] }
        cache[k] = NSImage(contentsOf: urls[k])
        return cache[k]
    }
}

private struct Photos: View {
    let t: Double
    var body: some View {
        let i = Int(t / 12)
        let p = fract(t / 12)
        GeometryReader { g in
            ZStack {
                if let im = PhotoLib.shared.image(i) {
                    Image(nsImage: im).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: g.size.width, height: g.size.height)
                        .scaleEffect(1.05 + 0.1 * p)
                        .offset(x: g.size.width * 0.02 * (p - 0.5) * (i % 2 == 0 ? 1 : -1))
                        .id(i)
                        .transition(.opacity)
                } else {
                    Mesh(t: t)
                    VStack(spacing: 8) {
                        Image(systemName: "photo.stack").font(.system(size: g.size.height * 0.08))
                        Text("Fotoordner in den Einstellungen wählen").font(.system(size: g.size.height * 0.03, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(width: g.size.width, height: g.size.height)
            .clipped()
            .animation(.easeInOut(duration: 1.6), value: i)
        }
    }
}
