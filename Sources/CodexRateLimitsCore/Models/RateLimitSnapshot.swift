import Foundation

public struct RateLimitSnapshot: Equatable, Sendable {
    public var weekLimit: RateLimitMetric
    public var fiveHourLimit: RateLimitMetric
    public var updatedAt: Date
    public var sourceDescription: String?

    public init(
        weekLimit: RateLimitMetric,
        fiveHourLimit: RateLimitMetric,
        updatedAt: Date = Date(),
        sourceDescription: String? = nil
    ) {
        self.weekLimit = weekLimit
        self.fiveHourLimit = fiveHourLimit
        self.updatedAt = updatedAt
        self.sourceDescription = sourceDescription
    }

    public var lowestRemainingFraction: Double {
        min(weekLimit.remainingFraction, fiveHourLimit.remainingFraction)
    }

    public func replacingSourceDescription(_ sourceDescription: String?) -> RateLimitSnapshot {
        var copy = self
        copy.sourceDescription = sourceDescription
        return copy
    }
}

extension RateLimitSnapshot: Codable {
    private enum CodingKeys: String, CodingKey {
        case weekLimit
        case fiveHourLimit
        case updatedAt
        case sourceDescription
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.weekLimit = try container.decode(RateLimitMetric.self, forKey: .weekLimit)
        self.fiveHourLimit = try container.decode(RateLimitMetric.self, forKey: .fiveHourLimit)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        self.sourceDescription = try container.decodeIfPresent(String.self, forKey: .sourceDescription)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(weekLimit, forKey: .weekLimit)
        try container.encode(fiveHourLimit, forKey: .fiveHourLimit)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(sourceDescription, forKey: .sourceDescription)
    }
}
