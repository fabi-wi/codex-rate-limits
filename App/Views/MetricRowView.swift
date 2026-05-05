import SwiftUI
import CodexRateLimitsCore

struct MetricRowView: View {
    let title: String
    let detail: String
    let metric: RateLimitMetric
    let tint: Color
    let now: Date

    private var displayTint: Color {
        LimitPalette.displayColor(for: metric, preferred: tint)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 7) {
                    Circle()
                        .fill(displayTint)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))

                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                Text(RateLimitFormatter.percentage(metric.remainingFraction))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            ProgressView(value: metric.remainingFraction)
                .tint(displayTint)
                .controlSize(.small)

            HStack {
                Text(remainingText)
                Spacer()
                Text(usedText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("resets \(RateLimitFormatter.relativeReset(metric.resetAt, relativeTo: now))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .animation(.easeInOut(duration: 0.25), value: metric.remainingFraction)
        .accessibilityElement(children: .combine)
    }

    private var remainingText: String {
        if metric.label == CodexUsageRateLimitProvider.percentageMetricLabel {
            return "\(RateLimitFormatter.percentage(metric.remainingFraction)) remaining"
        }

        return "\(RateLimitFormatter.count(metric.remaining)) remaining"
    }

    private var usedText: String {
        if metric.label == CodexUsageRateLimitProvider.percentageMetricLabel {
            return "\(RateLimitFormatter.percentage(metric.usedFraction)) used"
        }

        return "\(RateLimitFormatter.count(metric.used)) / \(RateLimitFormatter.count(metric.limit)) used"
    }
}
