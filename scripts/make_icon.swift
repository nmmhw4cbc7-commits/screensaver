// Renders the 1024px app icon: usage `swift scripts/make_icon.swift out.png`
import AppKit
let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()
let inset: CGFloat = 100, r = NSRect(x: inset, y: inset, width: S - 2 * inset, height: S - 2 * inset)
let shape = NSBezierPath(roundedRect: r, xRadius: 185, yRadius: 185)
NSGraphicsContext.current?.saveGraphicsState()
let sh = NSShadow(); sh.shadowBlurRadius = 30; sh.shadowOffset = .init(width: 0, height: -12); sh.shadowColor = .black.withAlphaComponent(0.35); sh.set()
NSColor.black.setFill(); shape.fill()
NSGraphicsContext.current?.restoreGraphicsState()
shape.addClip()
NSGradient(colors: [NSColor(red: 0.05, green: 0.05, blue: 0.25, alpha: 1), NSColor(red: 0.35, green: 0.2, blue: 0.85, alpha: 1), NSColor(red: 0.1, green: 0.85, blue: 0.75, alpha: 1)])!.draw(in: r, angle: 60)
for (c, x, y, d) in [(NSColor.systemPink, 0.25, 0.75, 520.0), (NSColor.systemTeal, 0.8, 0.3, 600.0)] {
    NSGradient(colors: [c.withAlphaComponent(0.55), c.withAlphaComponent(0)])!.draw(in: NSBezierPath(ovalIn: NSRect(x: S * x - d / 2, y: S * y - d / 2, width: d, height: d)), relativeCenterPosition: .zero)
}
let cfg = NSImage.SymbolConfiguration(pointSize: 400, weight: .medium).applying(.init(paletteColors: [.white]))
if let sym = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)?.withSymbolConfiguration(cfg) {
    let sz = sym.size
    sym.draw(in: NSRect(x: (S - sz.width) / 2, y: (S - sz.height) / 2, width: sz.width, height: sz.height))
}
img.unlockFocus()
let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
