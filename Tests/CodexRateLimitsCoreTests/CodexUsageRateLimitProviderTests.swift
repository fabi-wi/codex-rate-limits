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

        XCTAssertEqual(snapshot.fiveHourLimit.used, 3)
        XCTAssertEqual(snapshot.fiveHourLimit.limit, 100)
        XCTAssertEqual(snapshot.fiveHourLimit.remainingFraction, 0.97, accuracy: 0.0001)
        XCTAssertEqual(snapshot.fiveHourLimit.resetAt, Date(timeIntervalSince1970: 1_778_016_533))
        XCTAssertEqual(snapshot.fiveHourLimit.label, CodexUsageRateLimitProvider.percentageMetricLabel)

        XCTAssertEqual(snapshot.weekLimit.used, 0)
        XCTAssertEqual(snapshot.weekLimit.limit, 100)
        XCTAssertEqual(snapshot.weekLimit.remainingFraction, 1)
        XCTAssertEqual(snapshot.weekLimit.resetAt, Date(timeIntervalSince1970: 1_778_603_333))
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

        XCTAssertEqual(snapshot.fiveHourLimit.resetAt, Date(timeIntervalSince1970: 1_120))
        XCTAssertEqual(snapshot.weekLimit.resetAt, Date(timeIntervalSince1970: 1_240))
    }

    func testThrowsWhenRateLimitWindowsAreMissing() {
        let data = #"{"rate_limit":{"primary_window":{"used_percent":0}}}"#.data(using: .utf8)!

        XCTAssertThrowsError(try CodexUsageRateLimitProvider.decodeSnapshot(from: data)) { error in
            XCTAssertEqual(error as? CodexUsageProviderError, .missingRateLimitWindows)
        }
    }
}
