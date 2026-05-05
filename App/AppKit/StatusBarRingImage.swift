import AppKit
import CodexRateLimitsCore

enum StatusBarRingImage {
    static func make(snapshot: RateLimitSnapshot?) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let weekFraction = snapshot?.weekLimit.remainingFraction ?? 0
            let fiveHourFraction = snapshot?.fiveHourLimit.remainingFraction ?? 0
            let center = CGPoint(x: rect.midX, y: rect.midY)

            drawTrack(center: center, radius: 7.1, lineWidth: 2.2)
            drawTrack(center: center, radius: 4.1, lineWidth: 2.1)
            drawRing(
                center: center,
                radius: 7.1,
                fraction: weekFraction,
                lineWidth: 2.2,
                color: nsColor(for: weekFraction, preferred: .systemBlue)
            )
            drawRing(
                center: center,
                radius: 4.1,
                fraction: fiveHourFraction,
                lineWidth: 2.1,
                color: nsColor(for: fiveHourFraction, preferred: .systemGreen)
            )
            return true
        }

        image.isTemplate = false
        return image
    }

    private static func drawTrack(center: CGPoint, radius: CGFloat, lineWidth: CGFloat) {
        let rect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        let path = NSBezierPath(ovalIn: rect)
        path.lineWidth = lineWidth
        NSColor.labelColor.withAlphaComponent(0.16).setStroke()
        path.stroke()
    }

    private static func drawRing(
        center: CGPoint,
        radius: CGFloat,
        fraction: Double,
        lineWidth: CGFloat,
        color: NSColor
    ) {
        guard fraction > 0 else { return }

        let path = NSBezierPath()
        path.lineCapStyle = .round
        path.lineWidth = lineWidth
        path.appendArc(
            withCenter: center,
            radius: radius,
            startAngle: 90,
            endAngle: 90 - (360 * CGFloat(fraction)),
            clockwise: true
        )
        color.setStroke()
        path.stroke()
    }

    private static func nsColor(for fraction: Double, preferred: NSColor) -> NSColor {
        switch fraction {
        case ..<0.15:
            return .systemRed
        case ..<0.30:
            return .systemOrange
        default:
            return preferred
        }
    }
}
