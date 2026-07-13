import Foundation

public struct RateLimitSnapshot: Equatable, Sendable {
    public var limits: [RateLimitWindow]
    public var updatedAt: Date
    public var sourceDescription: String?

    public init(
        limits: [RateLimitWindow],
        updatedAt: Date = Date(),
        sourceDescription: String? = nil
    ) {
        self.limits = limits.sorted { lhs, rhs in
            (lhs.durationSeconds ?? 0) > (rhs.durationSeconds ?? 0)
        }
        self.updatedAt = updatedAt
        self.sourceDescription = sourceDescription
    }

    public var lowestRemainingFraction: Double {
        limits.map(\.metric.remainingFraction).min() ?? 0
    }

    public func replacingSourceDescription(_ sourceDescription: String?) -> RateLimitSnapshot {
        var copy = self
        copy.sourceDescription = sourceDescription
        return copy
    }
}

extension RateLimitSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case limits
        case weekLimit
        case fiveHourLimit
        case updatedAt
        case sourceDescription
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        let sourceDescription = try container.decodeIfPresent(String.self, forKey: .sourceDescription)

        if let limits = try container.decodeIfPresent([RateLimitWindow].self, forKey: .limits) {
            self.init(limits: limits, updatedAt: updatedAt, sourceDescription: sourceDescription)
            return
        }

        let weekLimit = try container.decodeIfPresent(RateLimitMetric.self, forKey: .weekLimit)
        let fiveHourLimit = try container.decodeIfPresent(RateLimitMetric.self, forKey: .fiveHourLimit)
        let legacyLimits = [
            weekLimit.map { RateLimitWindow(durationSeconds: 604_800, metric: $0, title: "Week Limit") },
            fiveHourLimit.map { RateLimitWindow(durationSeconds: 18_000, metric: $0, title: "5 Hour Limit") }
        ].compactMap { $0 }

        guard !legacyLimits.isEmpty else {
            throw DecodingError.keyNotFound(
                CodingKeys.limits,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Supply at least one rate-limit window."
                )
            )
        }

        self.init(limits: legacyLimits, updatedAt: updatedAt, sourceDescription: sourceDescription)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(limits, forKey: .limits)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(sourceDescription, forKey: .sourceDescription)
    }
}
