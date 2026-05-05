import SwiftUI
import CodexRateLimitsCore

struct MetricRowView: View {
    let title: String
    let detail: String
    let metric: RateLimitMetric
    let tint: Color

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
                Text("\(RateLimitFormatter.count(metric.remaining)) remaining")
                Spacer()
                Text("\(RateLimitFormatter.count(metric.used)) / \(RateLimitFormatter.count(metric.limit)) used")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("resets \(RateLimitFormatter.relativeReset(metric.resetAt))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .combine)
    }
}
