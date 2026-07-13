import XCTest
@testable import CodexRateLimitsCore

final class CodexUsageRateLimitProviderTests: XCTestCase {
    func testDecodesCodexUsageResponse() throws {
        let now = Date(timeIntervalSince1970: 1_778_000_000)
        let data = """
        {
          "rate_limit": {
            "allowed": true,
            "limit_reached": false,
            "primary_window": {
              "used_percent": 3,
              "limit_window_seconds": 18000,
              "reset_after_seconds": 17566,
              "reset_at": 1778016533
            },
            "secondary_window": {
              "used_percent": 0,
              "limit_window_seconds": 604800,
              "reset_after_seconds": 604366,
              "reset_at": 1778603333
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CodexUsageRateLimitProvider.decodeSnapshot(from: data, now: now)

        XCTAssertEqual(snapshot.limits.count, 2)

        let weekLimit = snapshot.limits[0]
        XCTAssertEqual(weekLimit.durationSeconds, 604_800)
        XCTAssertEqual(weekLimit.displayTitle, "Week Limit")
        XCTAssertEqual(weekLimit.metric.used, 0)
        XCTAssertEqual(weekLimit.metric.limit, 100)
        XCTAssertEqual(weekLimit.metric.remainingFraction, 1)
        XCTAssertEqual(weekLimit.metric.resetAt, Date(timeIntervalSince1970: 1_778_603_333))

        let fiveHourLimit = snapshot.limits[1]
        XCTAssertEqual(fiveHourLimit.durationSeconds, 18_000)
        XCTAssertEqual(fiveHourLimit.displayTitle, "5 Hour Limit")
        XCTAssertEqual(fiveHourLimit.metric.used, 3)
        XCTAssertEqual(fiveHourLimit.metric.limit, 100)
        XCTAssertEqual(fiveHourLimit.metric.remainingFraction, 0.97, accuracy: 0.0001)
        XCTAssertEqual(fiveHourLimit.metric.resetAt, Date(timeIntervalSince1970: 1_778_016_533))
        XCTAssertEqual(fiveHourLimit.metric.label, CodexUsageRateLimitProvider.percentageMetricLabel)
        XCTAssertEqual(snapshot.sourceDescription, "Codex usage")
    }

    func testUsesResetAfterSecondsWhenResetAtIsMissing() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let data = """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 8,
              "limit_window_seconds": 18000,
              "reset_after_seconds": 120
            },
            "secondary_window": {
              "used_percent": 12,
              "limit_window_seconds": 604800,
              "reset_after_seconds": 240
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CodexUsageRateLimitProvider.decodeSnapshot(from: data, now: now)

        XCTAssertEqual(snapshot.limits[0].metric.resetAt, Date(timeIntervalSince1970: 1_240))
        XCTAssertEqual(snapshot.limits[1].metric.resetAt, Date(timeIntervalSince1970: 1_120))
    }

    func testDecodesWeeklyWindowWhenSecondaryWindowIsNull() throws {
        let data = """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 4,
              "limit_window_seconds": 604800,
              "reset_after_seconds": 603856,
              "reset_at": 1784536763
            },
            "secondary_window": null
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CodexUsageRateLimitProvider.decodeSnapshot(from: data)

        XCTAssertEqual(snapshot.limits.count, 1)
        XCTAssertEqual(snapshot.limits[0].displayTitle, "Week Limit")
        XCTAssertEqual(snapshot.limits[0].metric.remainingFraction, 0.96, accuracy: 0.0001)
    }

    func testDecodesAdditionalNamedWindowWithoutProviderChanges() throws {
        let data = """
        {
          "rate_limit": {
            "primary_window": {
              "used_percent": 4,
              "limit_window_seconds": 18000
            },
            "secondary_window": {
              "used_percent": 8,
              "limit_window_seconds": 604800
            },
            "monthly_window": {
              "used_percent": 12,
              "limit_window_seconds": 2592000
            }
          }
        }
        """.data(using: .utf8)!

        let snapshot = try CodexUsageRateLimitProvider.decodeSnapshot(from: data)

        XCTAssertEqual(snapshot.limits.count, 3)
        XCTAssertEqual(snapshot.limits.map(\.displayTitle), ["Month Limit", "Week Limit", "5 Hour Limit"])
        XCTAssertEqual(snapshot.lowestRemainingFraction, 0.88, accuracy: 0.0001)
    }

    func testThrowsWhenRateLimitWindowsAreMissing() {
        let data = #"{"rate_limit":{"primary_window":{"used_percent":0}}}"#.data(using: .utf8)!

        XCTAssertNoThrow(try CodexUsageRateLimitProvider.decodeSnapshot(from: data))
    }

    func testThrowsWhenNoWindowObjectsArePresent() {
        let data = #"{"rate_limit":{"allowed":true,"secondary_window":null}}"#.data(using: .utf8)!

        XCTAssertThrowsError(try CodexUsageRateLimitProvider.decodeSnapshot(from: data)) { error in
            XCTAssertEqual(error as? CodexUsageProviderError, .missingRateLimitWindows)
        }
    }
}
