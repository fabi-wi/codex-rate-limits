import Foundation

struct AppConfiguration {
    let dataFileURL: URL

    static func load(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        arguments: [String] = CommandLine.arguments
    ) -> AppConfiguration {
        let fileURL = configuredDataFileURL(environment: environment, arguments: arguments)
        bootstrapDataFileIfNeeded(at: fileURL)
        return AppConfiguration(dataFileURL: fileURL)
    }

    private static func configuredDataFileURL(
        environment: [String: String],
        arguments: [String]
    ) -> URL {
        if let argumentPath = value(after: "--data-file", in: arguments) {
            return URL(fileURLWithPath: expandingTilde(in: argumentPath)).standardizedFileURL
        }

        if let environmentPath = environment["CODEX_RATE_LIMITS_FILE"], !environmentPath.isEmpty {
            return URL(fileURLWithPath: expandingTilde(in: environmentPath)).standardizedFileURL
        }

        return applicationSupportDirectory()
            .appendingPathComponent("ratelimits.json")
            .standardizedFileURL
    }

    private static func bootstrapDataFileIfNeeded(at fileURL: URL) {
        let fileManager = FileManager.default
        let directory = fileURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            guard !fileManager.fileExists(atPath: fileURL.path) else { return }

            if let sampleURL = Bundle.module.url(forResource: "ratelimits.sample", withExtension: "json") {
                try fileManager.copyItem(at: sampleURL, to: fileURL)
            }
        } catch {
            NSLog("CodexRateLimits: could not prepare data file at \(fileURL.path): \(error)")
        }
    }

    private static func applicationSupportDirectory() -> URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL.appendingPathComponent("CodexRateLimits", isDirectory: true)
    }

    private static func value(after flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag) else { return nil }
        let valueIndex = arguments.index(after: index)
        guard valueIndex < arguments.endIndex else { return nil }
        return arguments[valueIndex]
    }

    private static func expandingTilde(in path: String) -> String {
        (path as NSString).expandingTildeInPath
    }
}
