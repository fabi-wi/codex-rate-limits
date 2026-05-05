import Foundation

public struct RateLimitMetric: Equatable, Sendable {
    public var used: Double
    public var limit: Double
    public var resetAt: Date?
    public var label: String?

    public init(used: Double, limit: Double, resetAt: Date? = nil, label: String? = nil) {
        self.used = used
        self.limit = limit
        self.resetAt = resetAt
        self.label = label
    }

    public var remaining: Double {
        max(limit - used, 0)
    }

    public var usedFraction: Double {
        guard limit > 0 else { return 0 }
        return Self.clamp(used / limit)
    }

    public var remainingFraction: Double {
        guard limit > 0 else { return 0 }
        return Self.clamp(remaining / limit)
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}

extension RateLimitMetric: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case used
        case limit
        case remaining
        case percentRemaining
        case percentageRemaining
        case remainingPercent
        case resetAt
        case label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedLimit = try container.decodeIfPresent(Double.self, forKey: .limit)
        let resetAt = try container.decodeIfPresent(Date.self, forKey: .resetAt)
        let label = try container.decodeIfPresent(String.self, forKey: .label)

        if let used = try container.decodeIfPresent(Double.self, forKey: .used) {
            guard let limit = decodedLimit else {
                throw DecodingError.keyNotFound(
                    CodingKeys.limit,
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "`limit` is required when `used` is supplied."
                    )
                )
            }

            self.init(used: used, limit: limit, resetAt: resetAt, label: label)
            return
        }

        if let remaining = try container.decodeIfPresent(Double.self, forKey: .remaining) {
            let limit = decodedLimit ?? max(remaining, 1)
            self.init(used: max(limit - remaining, 0), limit: limit, resetAt: resetAt, label: label)
            return
        }

        if let percent = try container.decodeFirstPercentRemaining() {
            let limit = decodedLimit ?? 1
            let fraction = Self.normalizedPercent(percent)
            self.init(used: limit * (1 - fraction), limit: limit, resetAt: resetAt, label: label)
            return
        }

        throw DecodingError.keyNotFound(
            CodingKeys.used,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Supply `used`, `remaining`, or `percentRemaining` for each limit."
            )
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(used, forKey: .used)
        try container.encode(limit, forKey: .limit)
        try container.encodeIfPresent(resetAt, forKey: .resetAt)
        try container.encodeIfPresent(label, forKey: .label)
    }

    private static func normalizedPercent(_ value: Double) -> Double {
        let fraction = value > 1 ? value / 100 : value
        return clamp(fraction)
    }
}

private extension KeyedDecodingContainer where K == RateLimitMetric.CodingKeys {
    func decodeFirstPercentRemaining() throws -> Double? {
        if let value = try decodeIfPresent(Double.self, forKey: .percentRemaining) {
            return value
        }

        if let value = try decodeIfPresent(Double.self, forKey: .percentageRemaining) {
            return value
        }

        return try decodeIfPresent(Double.self, forKey: .remainingPercent)
    }
}
