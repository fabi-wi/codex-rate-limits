import AppKit
import CodexRateLimitsCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var store: RateLimitStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let configuration = AppConfiguration.load()
        let provider = LocalJSONRateLimitProvider(fileURL: configuration.dataFileURL)
        let store = RateLimitStore(provider: provider, dataFileURL: configuration.dataFileURL)

        self.store = store
        self.statusBarController = StatusBarController(store: store)
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        store?.stop()
    }
}
