import SwiftUI
import CodexRateLimitsCore

struct LimitRingsView: View {
    let snapshot: RateLimitSnapshot

    private var displayedLimits: [RateLimitWindow] {
        Array(snapshot.limits.prefix(3))
    }

    private func diameter(at index: Int) -> CGFloat {
        let outerDiameter: CGFloat = displayedLimits.count == 1 ? 138 : 154
        return max(outerDiameter - CGFloat(index * 40), 56)
    }

    private func lineWidth(at index: Int) -> CGFloat {
        max(12 - CGFloat(index), 8)
    }

    var body: some View {
        ZStack {
            ForEach(Array(displayedLimits.enumerated()), id: \.offset) { index, limit in
                let tint = LimitPalette.displayColor(
                    for: limit.metric,
                    preferred: LimitPalette.preferredColor(at: index)
                )

                Circle()
                    .stroke(.secondary.opacity(0.14), lineWidth: lineWidth(at: index))
                    .frame(width: diameter(at: index), height: diameter(at: index))

                Circle()
                    .trim(from: 0, to: CGFloat(limit.metric.remainingFraction))
                    .stroke(
                        tint,
                        style: StrokeStyle(
                            lineWidth: lineWidth(at: index),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .frame(width: diameter(at: index), height: diameter(at: index))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 2) {
                Text(RateLimitFormatter.percentage(snapshot.lowestRemainingFraction))
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                Text("remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 170, height: 170)
        .animation(.easeInOut(duration: 0.35), value: snapshot.lowestRemainingFraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        snapshot.limits
            .map { "\($0.displayTitle) \(RateLimitFormatter.percentage($0.metric.remainingFraction)) remaining." }
            .joined(separator: " ")
    }
}
