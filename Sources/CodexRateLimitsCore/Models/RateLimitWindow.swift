import Foundation

public struct RateLimitWindow: Codable, Equatable, Sendable {
    public var durationSeconds: Double?
    public var metric: RateLimitMetric
    public var title: String?

    public init(
        durationSeconds: Double? = nil,
        metric: RateLimitMetric,
        title: String? = nil
    ) {
        self.durationSeconds = durationSeconds
        self.metric = metric
        self.title = title
    }

    public var displayTitle: String {
        if let title, !title.isEmpty {
            return title
        }

        guard let durationSeconds, durationSeconds > 0 else {
            return "Usage Limit"
        }

        let hours = durationSeconds / 3_600
        let days = durationSeconds / 86_400

        if approximately(days, equals: 7) {
            return "Week Limit"
        }

        if days >= 28, days <= 31 {
            return "Month Limit"
        }

        if days >= 1, approximately(days, equals: days.rounded()) {
            return "\(Int(days.rounded())) Day Limit"
        }

        if hours >= 1, approximately(hours, equals: hours.rounded()) {
            return "\(Int(hours.rounded())) Hour Limit"
        }

        let minutes = max(Int((durationSeconds / 60).rounded()), 1)
        return "\(minutes) Minute Limit"
    }

    public var durationDescription: String {
        guard let durationSeconds, durationSeconds > 0 else {
            return "Usage window"
        }

        let days = durationSeconds / 86_400
        let hours = durationSeconds / 3_600

        if approximately(days, equals: 7) {
            return "7-day usage window"
        }

        if days >= 28, days <= 31 {
            return "Monthly usage window"
        }

        if days >= 1, approximately(days, equals: days.rounded()) {
            return "\(Int(days.rounded()))-day usage window"
        }

        if hours >= 1, approximately(hours, equals: hours.rounded()) {
            return "\(Int(hours.rounded()))-hour usage window"
        }

        let minutes = max(Int((durationSeconds / 60).rounded()), 1)
        return "\(minutes)-minute usage window"
    }

    private func approximately(_ value: Double, equals target: Double) -> Bool {
        abs(value - target) < 0.001
    }
}
