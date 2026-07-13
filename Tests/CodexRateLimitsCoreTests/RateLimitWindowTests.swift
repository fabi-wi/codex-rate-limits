import XCTest
@testable import CodexRateLimitsCore

final class RateLimitWindowTests: XCTestCase {
    func testGeneratesTitlesFromWindowDuration() {
        let metric = RateLimitMetric(used: 0, limit: 100)

        XCTAssertEqual(
            RateLimitWindow(durationSeconds: 18_000, metric: metric).displayTitle,
            "5 Hour Limit"
        )
        XCTAssertEqual(
            RateLimitWindow(durationSeconds: 604_800, metric: metric).displayTitle,
            "Week Limit"
        )
        XCTAssertEqual(
            RateLimitWindow(durationSeconds: 2_592_000, metric: metric).displayTitle,
            "Month Limit"
        )
    }
}
