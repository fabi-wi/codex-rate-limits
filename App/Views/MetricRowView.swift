import SwiftUI
import CodexRateLimitsCore

struct MetricRowView: View {
    let title: String
    let detail: String
    let metric: RateLimitMetric
    let now: Date

    private var displayTint: Color {
        LimitPalette.displayColor(for: metric)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
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

            CapsuleProgressBar(value: metric.remainingFraction, tint: displayTint)

            HStack {
                Text(remainingText)
                Spacer()
                Text(usedText)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ResetCountdownView(
                resetAt: metric.resetAt,
                now: now,
                prefersDays: title == "Week Limit"
            )
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

private struct CapsuleProgressBar: View {
    let value: Double
    let tint: Color

    private var clampedValue: CGFloat {
        CGFloat(min(max(value, 0), 1))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.secondary.opacity(0.14))

                Capsule()
                    .fill(tint)
                    .frame(width: max(proxy.size.width * clampedValue, clampedValue > 0 ? 6 : 0))
            }
        }
        .frame(height: 6)
        .animation(.easeInOut(duration: 0.35), value: value)
    }
}

private struct ResetCountdownView: View {
    let resetAt: Date?
    let now: Date
    let prefersDays: Bool

    var body: some View {
        Group {
            if let components = RateLimitFormatter.countdownComponents(until: resetAt, relativeTo: now) {
                Text("resets in \(countdown(components))")
                    .monospacedDigit()
                    .accessibilityLabel("resets in \(components.days) days, \(components.hours) hours, \(components.minutes) minutes, \(components.seconds) seconds")
            } else {
                Text("reset time unavailable")
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
    }

    private func countdown(_ components: RateLimitCountdownComponents) -> String {
        let days = prefersDays || components.days > 0 ? "\(components.days)d " : ""
        return "\(days)\(RateLimitFormatter.twoDigit(components.hours))h \(RateLimitFormatter.twoDigit(components.minutes))m \(RateLimitFormatter.twoDigit(components.seconds))s"
    }
}
