import Foundation

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

    public static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
