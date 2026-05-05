import SwiftUI

struct LiquidGlassBackground: View {
    private let cornerRadius: CGFloat = 26

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)

            LinearGradient(
                colors: [
                    Color(red: 0.92, green: 0.58, blue: 0.20).opacity(0.34),
                    Color(red: 0.55, green: 0.25, blue: 0.43).opacity(0.30),
                    Color(red: 0.03, green: 0.34, blue: 0.62).opacity(0.40)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.white.opacity(0.04),
                    Color.clear
                ],
                center: UnitPoint(x: 0.12, y: 0.02),
                startRadius: 8,
                endRadius: 230
            )

            RadialGradient(
                colors: [
                    LimitPalette.week.opacity(0.16),
                    Color.clear
                ],
                center: UnitPoint(x: 0.95, y: 0.88),
                startRadius: 12,
                endRadius: 270
            )

            LinearGradient(
                colors: [
                    Color.white.opacity(0.14),
                    Color.clear,
                    Color.black.opacity(0.24)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)

            Rectangle()
                .fill(.black.opacity(0.10))
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.32),
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}
