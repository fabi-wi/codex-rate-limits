import SwiftUI
import CodexRateLimitsCore

enum LimitPalette {
    static let week = Color(red: 0.14, green: 0.48, blue: 0.88)
    static let fiveHour = Color(red: 0.02, green: 0.67, blue: 0.50)
    static let warning = Color(red: 0.95, green: 0.55, blue: 0.18)
    static let critical = Color(red: 0.88, green: 0.22, blue: 0.24)

    static func displayColor(for metric: RateLimitMetric, preferred: Color) -> Color {
        switch metric.remainingFraction {
        case ..<0.15:
            return critical
        case ..<0.30:
            return warning
        default:
            return preferred
        }
    }
}
