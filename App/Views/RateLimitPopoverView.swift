import SwiftUI
import CodexRateLimitsCore

struct RateLimitPopoverView: View {
    static let preferredSize = CGSize(width: 340, height: 486)

    @ObservedObject var store: RateLimitStore

    let onRefresh: () -> Void
    let onRevealDataFile: () -> Void
    let onQuit: () -> Void

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

                GlassDivider()

                footer
            }
        }
        .frame(
            width: Self.preferredSize.width,
            height: Self.preferredSize.height,
            alignment: .top
        )
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Codex Rate Limits")
                    .font(.system(size: 15, weight: .semibold))

                Text("Week and 5-hour availability")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(store.errorMessage == nil ? Color.green : Color.orange)
                    .frame(width: 7, height: 7)

                Text(store.errorMessage == nil ? "Live" : "Check data")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func snapshotContent(_ snapshot: RateLimitSnapshot) -> some View {
        VStack(spacing: 12) {
            LimitRingsView(snapshot: snapshot)
                .padding(.top, 4)

            VStack(spacing: 11) {
                MetricRowView(
                    title: "Week Limit",
                    detail: "Outer circle",
                    metric: snapshot.weekLimit,
                    tint: LimitPalette.week
                )

                GlassDivider()

                MetricRowView(
                    title: "5 Hour Limit",
                    detail: "Inner circle",
                    metric: snapshot.fiveHourLimit,
                    tint: LimitPalette.fiveHour
                )
            }
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

            Text(store.dataFileURL.path)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
                .multilineTextAlignment(.center)
        }
        .frame(height: 354)
        .padding(.horizontal, 22)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack {
                if let snapshot = store.snapshot {
                    Text("Updated \(RateLimitFormatter.timestamp(snapshot.updatedAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Local JSON source")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button(action: onRefresh) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button(action: onRevealDataFile) {
                    Label("Data", systemImage: "doc.text.magnifyingglass")
                }

                Spacer()

                Button(action: onQuit) {
                    Label("Quit", systemImage: "power")
                }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
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
