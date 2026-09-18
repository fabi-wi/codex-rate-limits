import XCTest
@testable import CodexRateLimitsCore

final class CodexUsageRequestTests: XCTestCase {
    func testCoalescesConcurrentRefreshesAndUsesFreshRequests() throws {
        let fixture = try RequestFixture()
        defer { fixture.cleanUp() }
        let received = expectation(description: "One snapshot")
        fixture.provider.onSnapshot = { result in
            if case .failure(let error) = result { XCTFail(error.localizedDescription) }
            received.fulfill()
        }

        for _ in 0..<10 { fixture.provider.refreshNow() }
        wait(for: [received], timeout: 2)

        let requests = fixture.requests
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
        XCTAssertEqual(requests.first?.value(forHTTPHeaderField: "ChatGPT-Account-ID"), "test-account")
        XCTAssertEqual(requests.first?.timeoutInterval, 20)
        XCTAssertEqual(requests.first?.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    func testRereadsCredentialsAfterRefresh() throws {
        let fixture = try RequestFixture()
        defer { fixture.cleanUp() }
        let first = expectation(description: "First snapshot")
        fixture.provider.onSnapshot = { _ in first.fulfill() }
        fixture.provider.refreshNow()
        wait(for: [first], timeout: 2)

        try Data(#"{"tokens":{"access_token":"updated-token"}}"#.utf8).write(to: fixture.authURL)
        let second = expectation(description: "Second snapshot")
        fixture.provider.onSnapshot = { _ in second.fulfill() }
        fixture.provider.refreshNow()
        wait(for: [second], timeout: 2)
        XCTAssertEqual(fixture.requests.count, 2)
        XCTAssertEqual(fixture.requests.last?.value(forHTTPHeaderField: "Authorization"), "Bearer updated-token")
        XCTAssertNil(fixture.requests.last?.value(forHTTPHeaderField: "ChatGPT-Account-ID"))
    }

    func testStopCancelsInFlightRequestWithoutEmittingFailure() throws {
        let fixture = try RequestFixture()
        defer { fixture.cleanUp() }
        let started = expectation(description: "Request started")
        let cancelled = expectation(description: "Request cancelled")
        let unwanted = expectation(description: "No callback after stopping")
        unwanted.isInverted = true
        fixture.onStart = { started.fulfill() }
        fixture.onStop = { cancelled.fulfill() }
        fixture.provider.onSnapshot = { _ in unwanted.fulfill() }
        fixture.provider.refreshNow()
        wait(for: [started], timeout: 2)
        fixture.provider.stop()
        wait(for: [cancelled, unwanted], timeout: 0.5)
    }

    func testMissingChatGPTTokenProducesActionableError() throws {
        let fixture = try RequestFixture()
        defer { fixture.cleanUp() }
        try Data(#"{"OPENAI_API_KEY":"test-key","tokens":null}"#.utf8).write(to: fixture.authURL)
        let received = expectation(description: "Missing token error")
        fixture.provider.onSnapshot = { result in
            guard case .failure(let error) = result else { return XCTFail("Expected failure") }
            XCTAssertEqual(error as? CodexUsageProviderError, .missingAccessToken)
            received.fulfill()
        }
        fixture.provider.refreshNow()
        wait(for: [received], timeout: 2)
        XCTAssertTrue(fixture.requests.isEmpty)
    }

    func testHTTPFailureIsReported() throws {
        let fixture = try RequestFixture(statusCode: 401)
        defer { fixture.cleanUp() }
        let received = expectation(description: "Authentication error")
        fixture.provider.onSnapshot = { result in
            guard case .failure(let error) = result else { return XCTFail("Expected failure") }
            XCTAssertEqual(error as? CodexUsageProviderError, .httpStatus(401))
            XCTAssertTrue(error.localizedDescription.contains("Sign in again"))
            received.fulfill()
        }
        fixture.provider.refreshNow()
        wait(for: [received], timeout: 2)
    }

    func testLiveUsageWhenExplicitlyEnabled() throws {
        guard ProcessInfo.processInfo.environment["CODEX_RATE_LIMITS_LIVE_CHECK"] == "1" else {
            throw XCTSkip("Set CODEX_RATE_LIMITS_LIVE_CHECK=1 for a local signed-in smoke check.")
        }
        let provider = CodexUsageRateLimitProvider()
        defer { provider.stop() }
        let received = expectation(description: "Live usage")
        provider.onSnapshot = { result in
            switch result {
            case .success(let snapshot):
                XCTAssertFalse(snapshot.limits.isEmpty)
                XCTAssertTrue((0...1).contains(snapshot.lowestRemainingFraction))
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            received.fulfill()
        }
        provider.refreshNow()
        wait(for: [received], timeout: 25)
    }
}

private final class RequestFixture: @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var fixtures: [URL: RequestFixture] = [:]
    private let lock = NSLock()
    private var recordedRequests: [URLRequest] = []
    let authURL: URL
    let endpoint: URL
    let session: URLSession
    let provider: CodexUsageRateLimitProvider
    let statusCode: Int
    var onStart: (() -> Void)?
    var onStop: (() -> Void)?

    var requests: [URLRequest] { lock.withLock { recordedRequests } }

    init(statusCode: Int = 200) throws {
        authURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        endpoint = URL(string: "https://example.invalid/\(UUID().uuidString)")!
        self.statusCode = statusCode
        try Data(#"{"tokens":{"access_token":"test-token","account_id":"test-account"}}"#.utf8).write(to: authURL)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [UsageURLProtocol.self]
        session = URLSession(configuration: config)
        provider = CodexUsageRateLimitProvider(authFileURL: authURL, endpointURL: endpoint, session: session)
        Self.lock.withLock { Self.fixtures[endpoint] = self }
    }

    static func fixture(for url: URL) -> RequestFixture? { lock.withLock { fixtures[url] } }

    func record(_ request: URLRequest) {
        lock.withLock { recordedRequests.append(request) }
        onStart?()
    }

    func cleanUp() {
        provider.stop()
        session.invalidateAndCancel()
        _ = Self.lock.withLock { Self.fixtures.removeValue(forKey: endpoint) }
        try? FileManager.default.removeItem(at: authURL)
    }
}

private final class UsageURLProtocol: URLProtocol, @unchecked Sendable {
    private var responseWork: DispatchWorkItem?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let fixture = RequestFixture.fixture(for: request.url!) else { return }
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let response = HTTPURLResponse(url: self.request.url!, statusCode: fixture.statusCode, httpVersion: nil, headerFields: nil)!
            self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            self.client?.urlProtocol(self, didLoad: Data(#"{"rate_limit":{"primary_window":{"used_percent":20,"limit_window_seconds":18000}}}"#.utf8))
            self.client?.urlProtocolDidFinishLoading(self)
        }
        responseWork = work
        fixture.record(request)
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.15, execute: work)
    }

    override func stopLoading() {
        responseWork?.cancel()
        RequestFixture.fixture(for: request.url!)?.onStop?()
    }
}
