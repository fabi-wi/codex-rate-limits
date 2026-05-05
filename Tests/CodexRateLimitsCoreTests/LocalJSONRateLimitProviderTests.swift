import XCTest
@testable import CodexRateLimitsCore

final class LocalJSONRateLimitProviderTests: XCTestCase {
    func testReadSnapshotFromFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("ratelimits.json")
        try sampleData.write(to: fileURL)

        let provider = LocalJSONRateLimitProvider(fileURL: fileURL)
        let snapshot = try provider.readSnapshot()

        XCTAssertEqual(snapshot.weekLimit.limit, 200000)
        XCTAssertEqual(snapshot.fiveHourLimit.used, 16500)
        XCTAssertEqual(snapshot.sourceDescription, fileURL.path)
    }

    private var sampleData: Data {
        """
        {
          "weekLimit": { "used": 62000, "limit": 200000 },
          "fiveHourLimit": { "used": 16500, "limit": 50000 },
          "updatedAt": "2026-05-05T14:23:00Z"
        }
        """.data(using: .utf8)!
    }
}
