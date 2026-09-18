import AppKit
import SwiftUI
import CodexRateLimitsCore

enum LimitPalette {
    static func displayColor(for metric: RateLimitMetric) -> Color {
        Color(nsColor: color(for: metric.remainingFraction))
    }

    // One palette for popover rings, progress bars, and the menu-bar icon.
    static func color(for remainingFraction: Double) -> NSColor {
        switch remainingFraction {
        case ..<0.20:
            return .systemRed
        case ..<0.50:
            return .systemYellow
        default:
            return .systemGreen
        }
    }
}
