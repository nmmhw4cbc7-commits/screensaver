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

    // MARK: - Drag to place with center snapping
    private func widget(_ it: WItem, _ k: CGFloat, _ size: CGSize) -> some View {
        let selected = editing && selection.wrappedValue == it.id
        let sc = it.scale * k
        return WidgetView(item: it)
            .padding(10)
            .overlay {
                if selected {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2 / sc, dash: [8 / sc, 5 / sc]))
                }
            }
            .contentShape(Rectangle())
            .scaleEffect(sc)
            .position(x: size.width * it.x, y: size.height * it.y)
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .named("canvas")).onChanged { v in
                selection.wrappedValue = it.id
                guard let i = look.items.firstIndex(where: { $0.id == it.id }) else { return }
                var x = v.location.x / size.width, y = v.location.y / size.height
                if abs(x - 0.5) < 0.015 { x = 0.5 }
                if abs(y - 0.5) < 0.015 { y = 0.5 }
                look.items[i].x = min(0.97, max(0.03, x))
                look.items[i].y = min(0.97, max(0.03, y))
            }, including: editing ? .all : .subviews)
    }
}

// MARK: - Live look thumbnail
struct LookThumb: View {
    let look: Look
    var width: CGFloat = 240
    var fps: Double = 15
    var body: some View {
        SaverCanvas(look: .constant(look), fps: fps)
            .frame(width: width, height: width * 10 / 16)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)
    }
}
