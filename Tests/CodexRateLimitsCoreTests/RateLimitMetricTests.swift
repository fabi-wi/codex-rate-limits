import XCTest
@testable import CodexRateLimitsCore

final class RateLimitMetricTests: XCTestCase {
    func testRemainingFractionFromUsedAndLimit() {
        let metric = RateLimitMetric(used: 25, limit: 100)

        XCTAssertEqual(metric.remaining, 75)
        XCTAssertEqual(metric.usedFraction, 0.25)
        XCTAssertEqual(metric.remainingFraction, 0.75)
    }

    func testRemainingFractionClampsWhenUsedExceedsLimit() {
        let metric = RateLimitMetric(used: 125, limit: 100)

        XCTAssertEqual(metric.remaining, 0)
        XCTAssertEqual(metric.usedFraction, 1)
        XCTAssertEqual(metric.remainingFraction, 0)
    }

    func testDecodesRemainingBasedMetric() throws {
        let data = """
        {
          "weekLimit": { "remaining": 70, "limit": 100 },
          "fiveHourLimit": { "remaining": 25, "limit": 50 },
          "updatedAt": "2026-05-05T14:23:00Z"
        }
        """.data(using: .utf8)!

        let snapshot = try LocalJSONRateLimitProvider.decode(data)

        XCTAssertEqual(snapshot.weekLimit.used, 30)
        XCTAssertEqual(snapshot.weekLimit.remainingFraction, 0.7)
        XCTAssertEqual(snapshot.fiveHourLimit.used, 25)
        XCTAssertEqual(snapshot.fiveHourLimit.remainingFraction, 0.5)
    }

    func testDecodesPercentBasedMetric() throws {
        let data = """
        {
          "weekLimit": { "percentRemaining": 80 },
          "fiveHourLimit": { "percentageRemaining": 0.35 },
          "updatedAt": "2026-05-05T14:23:00Z"
        }
        """.data(using: .utf8)!

        let snapshot = try LocalJSONRateLimitProvider.decode(data)

        XCTAssertEqual(snapshot.weekLimit.remainingFraction, 0.8, accuracy: 0.0001)
        XCTAssertEqual(snapshot.fiveHourLimit.remainingFraction, 0.35, accuracy: 0.0001)
    }
}
