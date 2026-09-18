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
                tint: displayTint,
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
                    .fill(.white.opacity(0.12))

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
    let tint: Color
    let now: Date
    let prefersDays: Bool

    var body: some View {
        if let components = RateLimitFormatter.countdownComponents(until: resetAt, relativeTo: now) {
            HStack(alignment: .top, spacing: 9) {
                Text("resets in")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                    .frame(width: 62, alignment: .leading)
                    .padding(.top, 2)

                HStack(alignment: .top, spacing: 9) {
                    if showsDays(components) {
                        CountdownUnitView(
                            value: "\(components.days)d",
                            label: "days",
                            tint: tint
                        )
                    }

                    CountdownUnitView(
                        value: "\(RateLimitFormatter.twoDigit(hourValue(components)))h",
                        label: "hours",
                        tint: tint
                    )

                    CountdownUnitView(
                        value: "\(RateLimitFormatter.twoDigit(components.minutes))m",
                        label: "minutes",
                        tint: tint
                    )

                    CountdownUnitView(
                        value: "\(RateLimitFormatter.twoDigit(components.seconds))s",
                        label: "seconds",
                        tint: tint
                    )
                }
            }
            .accessibilityLabel("resets in \(components.days) days, \(components.hours) hours, \(components.minutes) minutes, \(components.seconds) seconds")
        } else {
            Text("reset time unavailable")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
    }

    private func showsDays(_ components: RateLimitCountdownComponents) -> Bool {
        prefersDays || components.days > 0
    }

    private func hourValue(_ components: RateLimitCountdownComponents) -> Int {
        showsDays(components) ? components.hours : components.totalHours
    }
}

private struct CountdownUnitView: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tint)
                .shadow(color: tint.opacity(0.24), radius: 5, x: 0, y: 0)

            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: 43)
    }
}
