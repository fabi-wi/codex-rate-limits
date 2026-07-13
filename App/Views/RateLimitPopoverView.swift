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
        ZStack {
            LiquidGlassBackground()

            VStack(spacing: 0) {
                header

                GlassDivider()

                Group {
                    if let snapshot = store.snapshot {
                        snapshotContent(snapshot)
                    } else {
                        emptyContent
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(
            width: Self.preferredWidth,
            height: Self.preferredHeight(limitCount: store.snapshot?.limits.count ?? 1),
            alignment: .top
        )
        .preferredColorScheme(.dark)
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
                    .fill(store.errorMessage == nil ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(store.errorMessage == nil ? "Live" : "Check data")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: onQuit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                        .frame(width: 28, height: 28)
                        .background(.white.opacity(0.14))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(.white.opacity(0.20), lineWidth: 1)
                        }
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
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
                LazyVStack(spacing: 11) {
                    ForEach(Array(snapshot.limits.enumerated()), id: \.offset) { index, limit in
                        MetricRowView(
                            title: limit.displayTitle,
                            detail: limit.durationDescription,
                            metric: limit.metric,
                            tint: LimitPalette.preferredColor(at: index),
                            now: now
                        )

                        if index < snapshot.limits.count - 1 {
                            GlassDivider()
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

private struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.11))
            .frame(height: 1)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.black.opacity(0.12))
                    .frame(height: 1)
            }
    }
}
