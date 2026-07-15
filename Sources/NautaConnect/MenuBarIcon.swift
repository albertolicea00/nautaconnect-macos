import AppKit

/// Draws the NautaConnect glyph (the curved "N" from assets/icon.svg) as a
/// template image so it adapts to light/dark menu bars automatically.
enum MenuBarIcon {
    static func image(size: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            // Original SVG path: M20 80 L20 20 C50 20 50 80 80 80 L80 20 (viewBox 100).
            let s = rect.width / 100
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }

            let path = NSBezierPath()
            path.move(to: p(20, 80))
            path.line(to: p(20, 20))
            path.curve(to: p(80, 80), controlPoint1: p(50, 20), controlPoint2: p(50, 80))
            path.line(to: p(80, 20))
            path.lineWidth = 14 * s
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}
