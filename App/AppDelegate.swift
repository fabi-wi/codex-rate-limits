import AppKit
import CodexRateLimitsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var store: RateLimitStore?
    private var codexTerminationObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configuration = AppConfiguration.load()
        let provider: RateLimitProviding

        switch configuration.source {
        case .codex:
            provider = CodexUsageRateLimitProvider(authFileURL: configuration.authFileURL)
        case .local:
            provider = LocalJSONRateLimitProvider(fileURL: configuration.dataFileURL)
        }

        let store = RateLimitStore(provider: provider, dataFileURL: configuration.dataFileURL)

        self.store = store
        self.statusBarController = StatusBarController(store: store)
        observeCodexTermination()
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.stop()
        if let codexTerminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(codexTerminationObserver)
        }
    }

    private func observeCodexTermination() {
        codexTerminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                Self.isCodex(application)
            else {
                return
            }

            Task { @MainActor in
                NSApplication.shared.terminate(nil)
            }
        }
    }

    nonisolated private static func isCodex(_ application: NSRunningApplication) -> Bool {
        application.bundleIdentifier == "com.openai.codex"
            || application.bundleURL?.path == "/Applications/Codex.app"
    }
}
