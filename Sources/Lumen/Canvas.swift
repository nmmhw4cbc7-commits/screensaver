import SwiftUI

// MARK: - Saver canvas with free widget placement
struct SaverCanvas: View {
    @Binding var look: Look
    var fps: Double = 60
    var editing = false
    var selection: Binding<UUID?> = .constant(nil)

    var body: some View {
        GeometryReader { g in
            let k = g.size.width / 1440
            ZStack {
                BackgroundView(bg: look.bg, speed: look.speed, hue: look.hue, dim: look.dim, fps: fps)
                TimelineView(.periodic(from: .now, by: 4)) { tl in
                    let t = editing ? 0 : tl.date.timeIntervalSinceReferenceDate
                    ZStack {
                        ForEach(look.items) { it in widget(it, k, g.size) }
                    }
                    .frame(width: g.size.width, height: g.size.height)
                    // slow drift protects against burn-in
                    .offset(x: editing ? 0 : 12 * k * sin(t / 40), y: editing ? 0 : 9 * k * cos(t / 53))
                    .animation(.easeInOut(duration: 4), value: t)
                }
            }
            .coordinateSpace(name: "canvas")
        }
    }
}
