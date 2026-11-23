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
