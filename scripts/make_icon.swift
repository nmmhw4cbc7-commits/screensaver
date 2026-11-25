// Renders the 1024px app icon: usage `swift scripts/make_icon.swift out.png`
import AppKit
let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let ctx = NSGraphicsContext.current!.cgContext
let inset: CGFloat = 100, r = NSRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let shape = NSBezierPath(roundedRect: r, xRadius: 185, yRadius: 185)
NSGraphicsContext.current?.saveGraphicsState()
let sh = NSShadow(); sh.shadowBlurRadius = 30; sh.shadowOffset = .init(width: 0, height: -12); sh.shadowColor = .black.withAlphaComponent(0.4); sh.set()
NSColor.black.setFill(); shape.fill()
NSGraphicsContext.current?.restoreGraphicsState()
shape.addClip()
NSGradient(colors: [NSColor(red: 0.03, green: 0.03, blue: 0.08, alpha: 1), NSColor(red: 0.1, green: 0.07, blue: 0.22, alpha: 1)])!.draw(in: r, angle: 90)
let c = CGPoint(x: S / 2, y: S / 2), R: CGFloat = 255
// soft glow behind ring
NSGradient(colors: [NSColor(red: 1, green: 0.4, blue: 0.5, alpha: 0.35), NSColor(red: 1, green: 0.4, blue: 0.5, alpha: 0)])!
    .draw(in: NSBezierPath(ovalIn: NSRect(x: c.x - 420, y: c.y - 420, width: 840, height: 840)), relativeCenterPosition: .zero)
// gradient ring: stroke arc as clip, fill with conic gradient
ctx.saveGState()
ctx.addArc(center: c, radius: R, startAngle: .pi * 0.5 - 0.35, endAngle: .pi * 0.5 + 0.35 - 2 * .pi, clockwise: true)
ctx.setLineWidth(70); ctx.setLineCap(.round)
ctx.replacePathWithStrokedPath(); ctx.clip()
let cols = [NSColor(red: 1, green: 0.78, blue: 0.3, alpha: 1), NSColor(red: 1, green: 0.35, blue: 0.45, alpha: 1), NSColor(red: 0.6, green: 0.35, blue: 1, alpha: 1), NSColor(red: 0.3, green: 0.8, blue: 1, alpha: 1)]
for i in 0..<360 {
    let a = CGFloat(i) * .pi / 180, f = CGFloat(i) / 360 * CGFloat(cols.count - 1)
    let k = Int(f), u = f - CGFloat(k)
    let c1 = cols[min(k, cols.count - 1)], c2 = cols[min(k + 1, cols.count - 1)]
    ctx.setFillColor(NSColor(red: c1.redComponent * (1 - u) + c2.redComponent * u, green: c1.greenComponent * (1 - u) + c2.greenComponent * u,
                             blue: c1.blueComponent * (1 - u) + c2.blueComponent * u, alpha: 1).cgColor)
    ctx.move(to: c)
    ctx.addArc(center: c, radius: 400, startAngle: .pi / 2 - a, endAngle: .pi / 2 - a - .pi / 170, clockwise: true)
    ctx.fillPath()
}
ctx.restoreGState()
// hands at 10:10
ctx.setStrokeColor(NSColor.white.cgColor); ctx.setLineCap(.round)
for (ang, len, w) in [(CGFloat(150), CGFloat(120), CGFloat(34)), (CGFloat(30), CGFloat(175), CGFloat(24))] {
    let rad = ang * .pi / 180
    ctx.setLineWidth(w); ctx.move(to: c); ctx.addLine(to: CGPoint(x: c.x + cos(rad) * len, y: c.y + sin(rad) * len)); ctx.strokePath()
}
ctx.setFillColor(NSColor.white.cgColor); ctx.fillEllipse(in: CGRect(x: c.x - 30, y: c.y - 30, width: 60, height: 60))
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
