import AppKit
import Foundation

enum CompanionLaunchSuppression {
    static func suppressForCurrentHostSession() {
        let value = runningHostPID().map(String.init) ?? "unknown"

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try value.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            NSLog("CodexRateLimits: could not write launch suppression marker: \(error)")
        }
    }

    private static var fileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CodexRateLimits", isDirectory: true)
            .appendingPathComponent("launch-suppressed-host.pid")
    }

    private static func runningHostPID() -> pid_t? {
        NSWorkspace.shared.runningApplications
            .first { application in
                application.bundleIdentifier == "com.openai.codex"
                    || application.bundleURL?.lastPathComponent == "Codex.app"
                    || application.bundleURL?.lastPathComponent == "ChatGPT.app"
            }?
            .processIdentifier
    }
}
