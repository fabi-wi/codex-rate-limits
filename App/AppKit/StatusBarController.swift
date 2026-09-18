import AppKit
import Combine
import SwiftUI
import CodexRateLimitsCore

@MainActor
final class StatusBarController: NSObject {
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
        if let errorMessage {
            button.title = "!"
            let updated = snapshot.map { "\nLast updated \(RateLimitFormatter.timestamp($0.updatedAt))" } ?? ""
            button.toolTip = "Codex rate limits: \(errorMessage)\(updated)"
        } else if let snapshot {
            button.title = RateLimitFormatter.percentage(snapshot.lowestRemainingFraction)
            let lines = snapshot.limits.map { limit in
                "\(limit.displayTitle): \(RateLimitFormatter.percentage(limit.metric.remainingFraction)) remaining"
            }
            button.toolTip = (["Codex rate limits"] + lines).joined(separator: "\n")
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

    func showPopover() {
        guard let button = statusItem.button else { return }

        store.refresh()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }
}
