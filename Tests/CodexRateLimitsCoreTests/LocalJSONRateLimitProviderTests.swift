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

    func testProviderEmitsUpdatedSnapshotWhenFileChanges() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let fileURL = directory.appendingPathComponent("ratelimits.json")
        try sampleData.write(to: fileURL)
        let updatedSampleData = updatedSampleData

        let provider = LocalJSONRateLimitProvider(fileURL: fileURL, pollInterval: 0.1)
        let updated = expectation(description: "Provider emits changed file contents")

        provider.onSnapshot = { result in
            guard case .success(let snapshot) = result else { return }

            if snapshot.weekLimit.used == 50000 && snapshot.fiveHourLimit.used == 10000 {
                updated.fulfill()
            }
        }

        provider.start()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            try? updatedSampleData.write(to: fileURL)
        }

        wait(for: [updated], timeout: 2)
        provider.stop()
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

    private var updatedSampleData: Data {
        """
        {
          "weekLimit": { "used": 50000, "limit": 200000 },
          "fiveHourLimit": { "used": 10000, "limit": 50000 },
          "updatedAt": "2026-05-05T15:00:00Z"
        }
        """.data(using: .utf8)!
    }
}
