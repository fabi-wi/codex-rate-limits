import Foundation

public struct RateLimitCountdownComponents: Equatable, Sendable {
    public let totalSeconds: Int
    public let days: Int
    public let hours: Int
    public let minutes: Int
    public let seconds: Int

    public init(timeInterval: TimeInterval) {
        let totalSeconds: Int
        if !timeInterval.isFinite || timeInterval <= 0 {
            totalSeconds = 0
        } else if timeInterval >= Double(Int.max) {
            totalSeconds = Int.max
        } else {
            totalSeconds = Int(ceil(timeInterval))
        }
        self.totalSeconds = totalSeconds
        days = totalSeconds / 86_400
        hours = (totalSeconds % 86_400) / 3_600
        minutes = (totalSeconds % 3_600) / 60
        seconds = totalSeconds % 60
    }

    public var totalHours: Int {
        totalSeconds / 3_600
    }
}

public enum RateLimitFormatter {
    public static func percentage(_ fraction: Double) -> String {
        let value = min(max(fraction, 0), 1) * 100
        return "\(Int(value.rounded()))%"
    }

    public static func count(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value < 100 ? 1 : 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(Int(value.rounded()))"
    }

    public static func relativeReset(_ date: Date?, relativeTo now: Date = Date()) -> String {
        guard let date else { return "No reset time" }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: now)
    }

    public static func countdownComponents(until date: Date?, relativeTo now: Date = Date()) -> RateLimitCountdownComponents? {
        guard let date else { return nil }
        return RateLimitCountdownComponents(timeInterval: date.timeIntervalSince(now))
    }

    public static func twoDigit(_ value: Int) -> String {
        String(format: "%02d", value)
    }

    public static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
