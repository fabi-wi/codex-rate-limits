import XCTest
@testable import CodexRateLimitsCore

final class RateLimitFormatterTests: XCTestCase {
    func testCountdownComponentsBreaksIntervalIntoDisplayUnits() {
        let components = RateLimitCountdownComponents(
            timeInterval: (6 * 86_400) + (4 * 3_600) + (32 * 60) + 18
        )

        XCTAssertEqual(components.days, 6)
        XCTAssertEqual(components.hours, 4)
        XCTAssertEqual(components.minutes, 32)
        XCTAssertEqual(components.seconds, 18)
        XCTAssertEqual(components.totalHours, 148)
    }

    func testCountdownComponentsClampsPastResetToZero() {
        let components = RateLimitCountdownComponents(timeInterval: -12)

        XCTAssertEqual(components.days, 0)
        XCTAssertEqual(components.hours, 0)
        XCTAssertEqual(components.minutes, 0)
        XCTAssertEqual(components.seconds, 0)
        XCTAssertEqual(components.totalSeconds, 0)
    }

    func testTwoDigitFormatterPadsSingleDigits() {
        XCTAssertEqual(RateLimitFormatter.twoDigit(3), "03")
        XCTAssertEqual(RateLimitFormatter.twoDigit(27), "27")
    }
    func testCountdownRoundsUpPartialSeconds() {
        XCTAssertEqual(RateLimitCountdownComponents(timeInterval: 0.1).totalSeconds, 1)
        XCTAssertEqual(RateLimitCountdownComponents(timeInterval: 59.1).minutes, 1)
    }

    func testCountdownHandlesInvalidAndVeryLargeIntervalsWithoutCrashing() {
        for interval in [Double.nan, Double.infinity, -Double.infinity] {
            XCTAssertEqual(RateLimitCountdownComponents(timeInterval: interval).totalSeconds, 0)
        }
        XCTAssertEqual(RateLimitCountdownComponents(timeInterval: Double.greatestFiniteMagnitude).totalSeconds, Int.max)
        XCTAssertNil(RateLimitFormatter.countdownComponents(until: nil))
    }

}
