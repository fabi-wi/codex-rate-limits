import SwiftUI
import CodexRateLimitsCore

struct LimitRingsView: View {
    let snapshot: RateLimitSnapshot

    private var weekColor: Color {
        LimitPalette.displayColor(for: snapshot.weekLimit, preferred: LimitPalette.week)
    }

    private var fiveHourColor: Color {
        LimitPalette.displayColor(for: snapshot.fiveHourLimit, preferred: LimitPalette.fiveHour)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.14), lineWidth: 12)
                .frame(width: 150, height: 150)

            Circle()
                .trim(from: 0, to: CGFloat(snapshot.weekLimit.remainingFraction))
                .stroke(
                    weekColor,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(-90))

            Circle()
                .stroke(.secondary.opacity(0.14), lineWidth: 10)
                .frame(width: 108, height: 108)

            Circle()
                .trim(from: 0, to: CGFloat(snapshot.fiveHourLimit.remainingFraction))
                .stroke(
                    fiveHourColor,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                )
                .frame(width: 108, height: 108)
                .rotationEffect(.degrees(-90))

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
        .animation(.easeInOut(duration: 0.35), value: snapshot.weekLimit.remainingFraction)
        .animation(.easeInOut(duration: 0.35), value: snapshot.fiveHourLimit.remainingFraction)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Week \(RateLimitFormatter.percentage(snapshot.weekLimit.remainingFraction)) remaining. 5 Hour \(RateLimitFormatter.percentage(snapshot.fiveHourLimit.remainingFraction)) remaining."
        )
    }
}
