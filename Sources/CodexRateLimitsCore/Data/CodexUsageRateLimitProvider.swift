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

        let windows = [rateLimit.primaryWindow, rateLimit.secondaryWindow].compactMap { $0 }
        guard
            let fiveHourWindow = closestWindow(in: windows, targetMinutes: 300, matching: { $0 < 1_440 }),
            let weekWindow = closestWindow(in: windows, targetMinutes: 10_080, matching: { $0 >= 1_440 })
        else {
            throw CodexUsageProviderError.missingRateLimitWindows
        }

        return RateLimitSnapshot(
            weekLimit: metric(from: weekWindow, now: now),
            fiveHourLimit: metric(from: fiveHourWindow, now: now),
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

    private static func closestWindow(
        in windows: [CodexUsageWindow],
        targetMinutes: Double,
        matching predicate: (Double) -> Bool
    ) -> CodexUsageWindow? {
        windows
            .filter { window in
                guard let minutes = window.windowMinutes else { return false }
                return predicate(minutes)
            }
            .min { lhs, rhs in
                abs((lhs.windowMinutes ?? 0) - targetMinutes) < abs((rhs.windowMinutes ?? 0) - targetMinutes)
            }
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
            return "Codex usage did not include both 5-hour and weekly rate-limit windows."
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
    let primaryWindow: CodexUsageWindow?
    let secondaryWindow: CodexUsageWindow?

    private enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

private struct CodexUsageWindow: Decodable {
    let usedPercent: Double?
    let limitWindowSeconds: Double?
    let resetAfterSeconds: Double?
    let resetAt: Double?

    var windowMinutes: Double? {
        limitWindowSeconds.map { $0 / 60 }
    }

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
