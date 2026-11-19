import SwiftUI

struct OvalGuide: View {
    private static let lineWidth: CGFloat = 8
    @Environment(\.livenessTheme) private var theme
    let oval: CGRect
    let guidance: LivenessGuidance

    var body: some View {
        ZStack {
            OvalScrim(oval: oval)
                .fill(Color(theme.background), style: FillStyle(eoFill: true))

            Ellipse()
                .stroke(Color(theme.track), lineWidth: Self.lineWidth)
                .frame(width: oval.width, height: oval.height)
                .position(x: oval.midX, y: oval.midY)

            OvalProgress(progress: guidance.progress)
                .stroke(
                    Color(guidance.isMatched ? theme.success : theme.accent),
                    style: StrokeStyle(lineWidth: Self.lineWidth, lineCap: .round, lineJoin: .round)
                )
                .frame(width: oval.width, height: oval.height)
                .position(x: oval.midX, y: oval.midY)
        }
        .animation(.easeOut(duration: 0.25), value: guidance.progress)
        .animation(.easeOut(duration: 0.2), value: guidance.isMatched)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct OvalScrim: Shape {
    let oval: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect.insetBy(dx: -2, dy: -2))
        path.addEllipse(in: oval)
        return path
    }
}
