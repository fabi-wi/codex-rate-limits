import AppKit
import Combine
import SwiftUI
import CodexRateLimitsCore

@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let store: RateLimitStore
    private var cancellables = Set<AnyCancellable>()

    init(store: RateLimitStore) {
        self.store = store
        super.init()

        configureStatusItem()
        configurePopover()
        bindStore()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        button.action = #selector(togglePopover(_:))
        button.target = self
        button.imagePosition = .imageLeading
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.title = "--"
        button.image = StatusBarRingImage.make(snapshot: nil)
        button.toolTip = "Codex rate limits"
        statusItem.length = 56
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentSize = NSSize(
            width: RateLimitPopoverView.preferredWidth,
            height: RateLimitPopoverView.preferredHeight(limitCount: 1)
        )
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: RateLimitPopoverView(
                store: store,
                onQuit: {
                    CompanionLaunchSuppression.suppressForCurrentHostSession()
                    NSApplication.shared.terminate(nil)
                }
            )
        )
    }

    private func bindStore() {
        store.$snapshot
            .combineLatest(store.$errorMessage)
            .sink { [weak self] snapshot, errorMessage in
                self?.renderStatusItem(snapshot: snapshot, errorMessage: errorMessage)
                self?.resizePopover(for: snapshot)
            }
            .store(in: &cancellables)
    }

    private func renderStatusItem(snapshot: RateLimitSnapshot?, errorMessage: String?) {
        guard let button = statusItem.button else { return }

        button.image = StatusBarRingImage.make(snapshot: snapshot)
        if let snapshot {
            button.title = RateLimitFormatter.percentage(snapshot.lowestRemainingFraction)
            let lines = snapshot.limits.map { limit in
                "\(limit.displayTitle): \(RateLimitFormatter.percentage(limit.metric.remainingFraction)) remaining"
            }
            button.toolTip = (["Codex rate limits"] + lines).joined(separator: "\n")
        } else if errorMessage != nil {
            button.title = "!"
            button.toolTip = "Codex rate limits: live usage could not be read"
        } else {
            button.title = "--"
            button.toolTip = "Codex rate limits"
        }
    }

    private func resizePopover(for snapshot: RateLimitSnapshot?) {
        popover.contentSize = NSSize(
            width: RateLimitPopoverView.preferredWidth,
            height: RateLimitPopoverView.preferredHeight(limitCount: snapshot?.limits.count ?? 1)
        )
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }

        store.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        configurePopoverWindow()
        positionPopoverBelowMenuBar(relativeTo: button)
    }

    func popoverDidShow(_ notification: Notification) {
        configurePopoverWindow()
        guard let button = statusItem.button else { return }
        positionPopoverBelowMenuBar(relativeTo: button)
    }

    private func configurePopoverWindow() {
        guard let window = popover.contentViewController?.view.window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
    }

    private func positionPopoverBelowMenuBar(relativeTo button: NSStatusBarButton) {
        guard
            let window = popover.contentViewController?.view.window,
            let buttonWindow = button.window,
            let screen = buttonWindow.screen ?? NSScreen.main
        else {
            return
        }

        let buttonFrame = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let visibleFrame = screen.visibleFrame
        let margin: CGFloat = 8
        let menuBarGap: CGFloat = 6
        var frame = window.frame

        frame.origin.x = buttonFrame.midX - (frame.width / 2)
        frame.origin.y = buttonFrame.minY - frame.height - menuBarGap

        frame.origin.x = min(
            max(frame.origin.x, visibleFrame.minX + margin),
            visibleFrame.maxX - frame.width - margin
        )
        frame.origin.y = min(
            frame.origin.y,
            visibleFrame.maxY - frame.height - margin
        )
        frame.origin.y = max(frame.origin.y, visibleFrame.minY + margin)

        window.setFrame(frame, display: true)
    }
}
