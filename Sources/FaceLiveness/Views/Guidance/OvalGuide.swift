import SwiftUI

struct OvalGuide: View {
    let oval: CGRect
    let guidance: LivenessGuidance

    var body: some View {
        TimelineView(.animation(paused: !guidance.motion.isAnimated)) { context in
            let sweep = guidance.motion.sweep(at: context.date, amplitude: 0.18)

            ZStack {
                OvalScrim(oval: oval)
                    .fill(Color.white.opacity(0.55), style: FillStyle(eoFill: true))

                Ellipse()
                    .stroke(Color.white.opacity(0.9), lineWidth: 4)
                    .frame(width: oval.width, height: oval.height)
                    .scaleEffect(sweep.scale)
                    .opacity(sweep.opacity)
                    .position(x: oval.midX, y: oval.midY)

                Ellipse()
                    .stroke(strokeColor, style: strokeStyle)
                    .frame(width: oval.width, height: oval.height)
                    .position(x: oval.midX, y: oval.midY)
            }
        }
        .animation(.easeOut(duration: 0.2), value: guidance.tone)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var strokeColor: Color {
        guidance.tone == .guide ? .white : guidance.tone.color
    }

    private var strokeStyle: StrokeStyle {
        guidance.tone == .guide
            ? StrokeStyle(lineWidth: 5, lineCap: .round, dash: [14, 10])
            : StrokeStyle(lineWidth: 7, lineCap: .round)
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
