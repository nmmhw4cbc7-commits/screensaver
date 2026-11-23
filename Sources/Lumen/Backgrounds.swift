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
