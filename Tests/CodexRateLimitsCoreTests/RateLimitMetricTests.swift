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

        XCTAssertEqual(snapshot.limits[0].metric.used, 30)
        XCTAssertEqual(snapshot.limits[0].metric.remainingFraction, 0.7)
        XCTAssertEqual(snapshot.limits[1].metric.used, 25)
        XCTAssertEqual(snapshot.limits[1].metric.remainingFraction, 0.5)
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

        XCTAssertEqual(snapshot.limits[0].metric.remainingFraction, 0.8, accuracy: 0.0001)
        XCTAssertEqual(snapshot.limits[1].metric.remainingFraction, 0.35, accuracy: 0.0001)
    }

    func testDecodesExpandableLimitsSchema() throws {
        let data = """
        {
          "limits": [
            {
              "durationSeconds": 2592000,
              "metric": { "percentRemaining": 75 }
            }
          ],
          "updatedAt": "2026-07-13T12:00:00Z"
        }
        """.data(using: .utf8)!

        let snapshot = try LocalJSONRateLimitProvider.decode(data)

        XCTAssertEqual(snapshot.limits.count, 1)
        XCTAssertEqual(snapshot.limits[0].displayTitle, "Month Limit")
        XCTAssertEqual(snapshot.limits[0].metric.remainingFraction, 0.75, accuracy: 0.0001)
    }
}
