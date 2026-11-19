import SwiftUI

struct FaceFillRing: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(LivenessStyle.track, lineWidth: lineWidth)

            fillHalf
            fillHalf
                .scaleEffect(x: -1, y: 1)
        }
        .animation(.easeOut(duration: 0.25), value: progress)
        .accessibilityHidden(true)
    }

    private var fillHalf: some View {
        Circle()
            .trim(from: 0, to: min(max(progress, 0), 1) / 2)
            .stroke(
                LivenessStyle.success,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(90))
    }
}
