import AppKit
import CodexRateLimitsCore

enum StatusBarRingImage {
    static func make(snapshot: RateLimitSnapshot?) -> NSImage {
        let size = NSSize(width: 22, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let limits = Array((snapshot?.limits ?? []).prefix(3))
            let center = CGPoint(x: rect.midX, y: rect.midY)

            for (index, limit) in limits.enumerated() {
                let radius = limits.count == 1 ? 5.7 : 7.2 - CGFloat(index) * 2.6
                let lineWidth = max(2.2 - CGFloat(index) * 0.15, 1.8)
                let fraction = limit.metric.remainingFraction

                drawTrack(center: center, radius: radius, lineWidth: lineWidth)
                drawRing(
                    center: center,
                    radius: radius,
                    fraction: fraction,
                    lineWidth: lineWidth,
                    color: nsColor(for: fraction, preferred: preferredColor(at: index))
                )
            }
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

    private static func preferredColor(at index: Int) -> NSColor {
        switch index % 3 {
        case 0: return .systemBlue
        case 1: return .systemGreen
        default: return .systemPurple
        }
    }
}
