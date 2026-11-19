import SwiftUI

struct FaceFillRing: View {
    @Environment(\.livenessTheme) private var theme
    let progress: Double
    let isMatched: Bool
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(theme.track), lineWidth: lineWidth)

            fillHalf
            fillHalf
                .scaleEffect(x: -1, y: 1)
        }
        .animation(.easeOut(duration: 0.25), value: progress)
        .animation(.easeOut(duration: 0.2), value: isMatched)
        .accessibilityHidden(true)
    }

    private var fillHalf: some View {
        Circle()
            .trim(from: 0, to: min(max(progress, 0), 1) / 2)
            .stroke(
                Color(isMatched ? theme.success : theme.accent),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(90))
    }
}
