import SwiftUI

struct OvalGuide: View {
    @Environment(\.livenessTheme) private var theme
    let oval: CGRect
    let guidance: LivenessGuidance

    var body: some View {
        TimelineView(.animation(paused: !guidance.motion.isAnimated)) { context in
            let sweep = guidance.motion.sweep(at: context.date, amplitude: 0.18)

            ZStack {
                OvalScrim(oval: oval)
                    .fill(Color(theme.background).opacity(0.6), style: FillStyle(eoFill: true))

                Ellipse()
                    .stroke(Color.white.opacity(0.9), lineWidth: 3)
                    .frame(width: oval.width, height: oval.height)
                    .scaleEffect(sweep.scale)
                    .opacity(sweep.opacity)
                    .position(x: oval.midX, y: oval.midY)

                Ellipse()
                    .stroke(guidance.isMatched ? Color(theme.success) : .white, lineWidth: 4)
                    .frame(width: oval.width, height: oval.height)
                    .position(x: oval.midX, y: oval.midY)
            }
        }
        .animation(.easeOut(duration: 0.2), value: guidance.isMatched)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct OvalScrim: Shape {
    let oval: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addEllipse(in: oval)
        return path
    }
}
