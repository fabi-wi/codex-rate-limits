import Combine
import SwiftUI
import CodexRateLimitsCore

struct RateLimitPopoverView: View {
    static let preferredWidth: CGFloat = 340

    static func preferredHeight(limitCount: Int) -> CGFloat {
        let count = max(limitCount, 1)
        return min(280 + CGFloat(count * 88), 680)
    }

    @ObservedObject var store: RateLimitStore
    @State private var now = Date()

    let onQuit: () -> Void

    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if let message = store.errorMessage, let snapshot = store.snapshot {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Last updated \(RateLimitFormatter.timestamp(snapshot.updatedAt))")
                        .fontWeight(.semibold)
                    Text(message)
                        .lineLimit(2)
                }
                .font(.caption)
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .help(message)
            }

            Group {
                if let snapshot = store.snapshot {
                    snapshotContent(snapshot)
                } else {
                    emptyContent
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(
            width: Self.preferredWidth,
            height: Self.preferredHeight(limitCount: store.snapshot?.limits.count ?? 1),
            alignment: .top
        )
        .onReceive(clock) { now = $0 }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Codex Rate Limits")
                    .font(.system(size: 15, weight: .semibold))

                Text("Available usage windows")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Circle()
                    .fill(store.errorMessage == nil && !store.isLoading ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(store.isLoading ? "Loading" : (store.errorMessage == nil ? "Live" : (store.snapshot == nil ? "Error" : "Stale")))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: onQuit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.quaternary, in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quit Codex Rate Limits")
                .help("Close Codex Rate Limits")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func snapshotContent(_ snapshot: RateLimitSnapshot) -> some View {
        VStack(spacing: 12) {
            LimitRingsView(snapshot: snapshot)
                .padding(.top, 4)

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(Array(snapshot.limits.enumerated()), id: \.offset) { index, limit in
                        MetricRowView(
                            title: limit.displayTitle,
                            detail: limit.durationDescription,
                            metric: limit.metric,
                            now: now
                        )

                        if index < snapshot.limits.count - 1 {
                            Divider()
                        }
                    }
                }
            }
            .scrollIndicators(snapshot.limits.count > 4 ? .visible : .hidden)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var emptyContent: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
                .opacity(store.isLoading ? 1 : 0)

            Text(store.errorMessage ?? "Waiting for rate-limit data")
                .font(.system(size: 13, weight: .medium))
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 22)
    }
}
