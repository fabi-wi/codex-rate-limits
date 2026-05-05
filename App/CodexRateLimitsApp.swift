import AppKit

@main
@MainActor
enum CodexRateLimitsApp {
    private static var appDelegate: AppDelegate?

    static func main() {
        let application = NSApplication.shared
        let delegate = AppDelegate()

        appDelegate = delegate
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }
}
