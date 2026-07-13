import Foundation

public final class CodexUsageRateLimitProvider: RateLimitProviding, @unchecked Sendable {
    public static let percentageMetricLabel = "percentage"

    public var onSnapshot: RateLimitProviderHandler?

    private let authFileURL: URL
    private let endpointURL: URL
    private let pollInterval: TimeInterval
    private let session: URLSession
    private let queue = DispatchQueue(label: "com.codexratelimits.codex-usage-provider")
    private var timer: DispatchSourceTimer?

    public init(
        authFileURL: URL = CodexUsageRateLimitProvider.defaultAuthFileURL(),
        endpointURL: URL = URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
        pollInterval: TimeInterval = 30,
        session: URLSession = .shared
    ) {
        self.authFileURL = authFileURL
        self.endpointURL = endpointURL
        self.pollInterval = pollInterval
        self.session = session
    }

    deinit {
        stop()
    }

    public func start() {
        queue.async { [weak self] in
            guard let self, self.timer == nil else { return }

            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now(), repeating: self.pollInterval)
            timer.setEventHandler { [weak self] in
                self?.load()
            }

            self.timer = timer
            timer.resume()
        }
    }

    public func stop() {
        queue.async { [weak self] in
            self?.timer?.cancel()
            self?.timer = nil
        }
    }

    public func refreshNow() {
        queue.async { [weak self] in
            self?.load()
        }
    }

    public static func decodeSnapshot(from data: Data, now: Date = Date()) throws -> RateLimitSnapshot {
        let response = try JSONDecoder().decode(CodexUsageResponse.self, from: data)
        guard let rateLimit = response.rateLimit else {
            throw CodexUsageProviderError.missingRateLimit
        }

        guard !rateLimit.windows.isEmpty else {
            throw CodexUsageProviderError.missingRateLimitWindows
        }

        return RateLimitSnapshot(
            limits: rateLimit.windows.map { window in
                RateLimitWindow(
                    durationSeconds: window.limitWindowSeconds,
                    metric: metric(from: window, now: now)
                )
            },
            updatedAt: now,
            sourceDescription: "Codex usage"
        )
    }

    public static func defaultAuthFileURL() -> URL {
        FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json")
    }

    private func load() {
        do {
            let request = try makeRequest()
            session.dataTask(with: request) { [weak self] data, response, error in
                if let error {
                    self?.emit(.failure(error))
                    return
                }

                do {
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw CodexUsageProviderError.invalidResponse
                    }

                    guard (200..<300).contains(httpResponse.statusCode) else {
                        throw CodexUsageProviderError.httpStatus(httpResponse.statusCode)
                    }

                    guard let data else {
                        throw CodexUsageProviderError.emptyResponse
                    }

                    let snapshot = try Self.decodeSnapshot(from: data)
                    self?.emit(.success(snapshot))
                } catch {
                    self?.emit(.failure(error))
                }
            }.resume()
        } catch {
            emit(.failure(error))
        }
    }

    private func makeRequest() throws -> URLRequest {
        let credentials = try readCredentials()
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "GET"
        request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let accountID = credentials.accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-ID")
        }

        return request
    }

    private func readCredentials() throws -> CodexAuthCredentials {
        let data = try Data(contentsOf: authFileURL)
        let auth = try JSONDecoder().decode(CodexAuthFile.self, from: data)

        guard let accessToken = auth.tokens.accessToken, !accessToken.isEmpty else {
            throw CodexUsageProviderError.missingAccessToken
        }

        return CodexAuthCredentials(accessToken: accessToken, accountID: auth.tokens.accountID)
    }

    private func emit(_ result: Result<RateLimitSnapshot, Error>) {
        onSnapshot?(result)
    }

    private static func metric(from window: CodexUsageWindow, now: Date) -> RateLimitMetric {
        let usedPercent = min(max(window.usedPercent ?? 0, 0), 100)
        return RateLimitMetric(
            used: usedPercent,
            limit: 100,
            resetAt: window.resetDate(relativeTo: now),
            label: Self.percentageMetricLabel
        )
    }
}

public enum CodexUsageProviderError: LocalizedError, Equatable {
    case emptyResponse
    case httpStatus(Int)
    case invalidResponse
    case missingAccessToken
    case missingRateLimit
    case missingRateLimitWindows

    public var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Codex usage returned an empty response."
        case .httpStatus(let statusCode):
            return "Codex usage request failed with HTTP \(statusCode)."
        case .invalidResponse:
            return "Codex usage returned an invalid response."
        case .missingAccessToken:
            return "No Codex ChatGPT access token was found in ~/.codex/auth.json."
        case .missingRateLimit:
            return "Codex usage did not include rate-limit data."
        case .missingRateLimitWindows:
            return "Codex usage did not include any rate-limit windows."
        }
    }
}

private struct CodexAuthFile: Decodable {
    let tokens: CodexAuthTokens
}

private struct CodexAuthTokens: Decodable {
    let accessToken: String?
    let accountID: String?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case accountID = "account_id"
    }
}

private struct CodexAuthCredentials {
    let accessToken: String
    let accountID: String?
}

private struct CodexUsageResponse: Decodable {
    let rateLimit: CodexRateLimit?

    private enum CodingKeys: String, CodingKey {
        case rateLimit = "rate_limit"
    }
}

private struct CodexRateLimit: Decodable {
    let windows: [CodexUsageWindow]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        windows = try container.allKeys
            .filter { $0.stringValue.hasSuffix("_window") }
            .sorted { $0.stringValue < $1.stringValue }
            .compactMap { key in
                try container.decodeIfPresent(CodexUsageWindow.self, forKey: key)
            }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = String(intValue)
        self.intValue = intValue
    }
}

private struct CodexUsageWindow: Decodable {
    let usedPercent: Double?
    let limitWindowSeconds: Double?
    let resetAfterSeconds: Double?
    let resetAt: Double?

    func resetDate(relativeTo now: Date) -> Date? {
        if let resetAt {
            return Date(timeIntervalSince1970: resetAt)
        }

        if let resetAfterSeconds {
            return now.addingTimeInterval(resetAfterSeconds)
        }

        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }
}
