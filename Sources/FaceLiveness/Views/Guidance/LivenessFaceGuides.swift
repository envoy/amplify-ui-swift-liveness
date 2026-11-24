import SwiftUI

/// The guides drawn on the camera image for a step: the tint or the oval with its ring, and the
/// helper shapes (face brackets, the growing or shrinking ring, side chevrons, extra-face marks).
struct LivenessFaceGuides: View {
    /// A ring the size of the face grows out to the oval, showing how big to get.
    private static let grow = (
        scale: LivenessKeyframes([(0, 1), (0.15, 1), (0.7, 1.5), (1, 1.5)], curve: .glide),
        opacity: LivenessKeyframes([(0, 0), (0.15, 0.9), (0.7, 0.9), (1, 0)], curve: .glide)
    )
    /// The reverse, from beyond the oval down to it.
    private static let shrink = (
        scale: LivenessKeyframes([(0, 1.32), (0.15, 1.32), (0.7, 1), (1, 1)], curve: .glide),
        opacity: LivenessKeyframes([(0, 0), (0.15, 0.9), (0.7, 0.9), (1, 0)], curve: .glide)
    )
    /// Chevrons that light up one after another toward where to move.
    private static let nudge = LivenessKeyframes([(0, 0.25), (0.4, 1), (1, 0.25)], curve: .easeInOut)
    /// Holding still: the ring closes, then turns green.
    private static let ringClose = LivenessKeyframes([(0, 0.78), (1, 1)], curve: .glide)
    private static let ringCloseDuration: TimeInterval = 0.98
    private static let matchFade = LivenessKeyframes([(0, 0), (0.896, 0), (1.176, 1)], curve: .easeInOut)

    let step: LivenessCaptureStep
    /// The service's oval on screen, once it is shown.
    let oval: CGRect?
    let face: CGRect?
    let otherFaces: [CGRect]
    /// The part of the camera the service checks, centring the guides before the oval is up.
    let checkedRect: CGRect
    /// When the current step began, so its loops start from their beginning.
    let start: Date

    var body: some View {
        LivenessClock(since: start) { seconds in
            ZStack(alignment: .topLeading) {
                tint
                if let oval {
                    ring(in: oval, seconds: seconds)
                    helper(in: oval, seconds: seconds)
                }
                if step == .faceFound, let face {
                    LivenessFaceBrackets(rect: Self.headRect(around: face))
                        .stroke(Color.white.opacity(0.9), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .animation(.easeOut(duration: 0.15), value: face)
                }
                if case .moveToSide(let towardRight) = step {
                    sideChevrons(towardRight: towardRight, seconds: seconds)
                }
                if step == .onlyOnePerson {
                    ForEach(Array(otherFaces.enumerated()), id: \.offset) { _, other in
                        let head = Self.headRect(around: other)
                        Ellipse()
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [3, 11]))
                            .frame(width: head.width, height: head.height)
                            .position(x: head.midX, y: head.midY)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The whole head around a detected face box, which runs only from the brows to the chin.
    static func headRect(around face: CGRect) -> CGRect {
        let width = face.width * 1.5
        let height = face.height * 1.55
        return CGRect(
            x: face.midX - width / 2,
            y: face.midY - face.height * 0.08 - height / 2,
            width: width,
            height: height
        )
    }

    @ViewBuilder
    private var tint: some View {
        if let oval {
            LivenessOvalCutout(oval: oval)
                .fill(LivenessCaptureStyle.scrim.opacity(LivenessCaptureStyle.scrimOpacity), style: FillStyle(eoFill: true))
        } else {
            LivenessCaptureStyle.scrim.opacity(
                step == .faceFound ? LivenessCaptureStyle.faceFoundTintOpacity : LivenessCaptureStyle.searchTintOpacity
            )
        }
    }

    @ViewBuilder
    private func ring(in oval: CGRect, seconds: TimeInterval) -> some View {
        let isHolding = step == .holdStill
        let progress = isHolding
            ? Self.ringClose.value(at: min(seconds / Self.ringCloseDuration, 1))
            : step.ringProgress
        Ellipse()
            .stroke(Color.white.opacity(LivenessCaptureStyle.trackOpacity), lineWidth: LivenessCaptureStyle.ringWidth)
            .frame(width: oval.width, height: oval.height)
            .position(x: oval.midX, y: oval.midY)
        if progress > 0 {
            ForEach([true, false], id: \.self) { left in
                LivenessHalfOval(oval: oval, left: left)
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: LivenessCaptureStyle.ringWidth, lineCap: .round))
            }
            .animation(isHolding ? nil : .easeOut(duration: 0.25), value: progress)
        }
        if isHolding {
            Ellipse()
                .stroke(LivenessCaptureStyle.matched, lineWidth: LivenessCaptureStyle.ringWidth)
                .frame(width: oval.width, height: oval.height)
                .position(x: oval.midX, y: oval.midY)
                .opacity(Self.matchFade.value(at: min(seconds, 1.176)))
        }
    }

    @ViewBuilder
    private func helper(in oval: CGRect, seconds: TimeInterval) -> some View {
        switch step {
        case .fillOval:
            let phase = seconds.truncatingRemainder(dividingBy: 2.2) / 2.2
            Ellipse()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 12]))
                .frame(width: oval.width / 1.5, height: oval.height / 1.5)
                .scaleEffect(Self.grow.scale.value(at: phase))
                .opacity(Self.grow.opacity.value(at: phase))
                .position(x: oval.midX, y: oval.midY)
        case .moveBack:
            let phase = seconds.truncatingRemainder(dividingBy: 2.2) / 2.2
            Ellipse()
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 12]))
                .frame(width: oval.width, height: oval.height)
                .scaleEffect(Self.shrink.scale.value(at: phase))
                .opacity(Self.shrink.opacity.value(at: phase))
                .position(x: oval.midX, y: oval.midY)
        default:
            EmptyView()
        }
    }

    /// Three chevrons at the middle, level with the face, leading toward where it should be.
    private func sideChevrons(towardRight: Bool, seconds: TimeInterval) -> some View {
        let target = oval ?? checkedRect
        let centerX = target.midX + (towardRight ? -9 : 9)
        let centerY = face?.midY ?? target.midY
        return ForEach(0..<3, id: \.self) { index in
            // Each chevron is 16 wide and 60 tall, 34 apart, lit in turn toward the target.
            let order = towardRight ? index : 2 - index
            let x = centerX - 42 + CGFloat(index) * 34
            Path { path in
                let back: CGFloat = towardRight ? 0 : 16
                let tip: CGFloat = towardRight ? 16 : 0
                path.move(to: CGPoint(x: x + back, y: centerY - 30))
                path.addLine(to: CGPoint(x: x + tip, y: centerY))
                path.addLine(to: CGPoint(x: x + back, y: centerY + 30))
            }
            .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .opacity(Self.nudge.value(atSeconds: seconds, period: 1.6, delay: 0.15 * Double(order)))
        }
    }
}

/// The screen with an oval hole, filled even-odd so only the outside is tinted.
struct LivenessOvalCutout: Shape {
    let oval: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -2, dy: -2))
        path.addEllipse(in: oval)
        return path
    }
}

/// One side of the oval, from the bottom up to the top, so progress fills from the chin up.
struct LivenessHalfOval: Shape {
    let oval: CGRect
    let left: Bool

    func path(in _: CGRect) -> Path {
        let steps = 96
        var path = Path()
        for step in 0...steps {
            // From the bottom (90°) round to the top (270° on the left, -90° on the right).
            let angle = Double.pi / 2 + (left ? 1 : -1) * Double.pi * Double(step) / Double(steps)
            let point = CGPoint(
                x: oval.midX + oval.width / 2 * cos(angle),
                y: oval.midY + oval.height / 2 * sin(angle)
            )
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

/// Four rounded corners around the face, like a camera's focus brackets.
struct LivenessFaceBrackets: Shape {
    var rect: CGRect

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(AnimatablePair(rect.minX, rect.minY), AnimatablePair(rect.width, rect.height)) }
        set { rect = CGRect(x: newValue.first.first, y: newValue.first.second, width: newValue.second.first, height: newValue.second.second) }
    }

    func path(in _: CGRect) -> Path {
        let length: CGFloat = 34
        let radius: CGFloat = 10
        let (x0, y0, x1, y1) = (rect.minX, rect.minY, rect.maxX, rect.maxY)
        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0 + length))
        path.addLine(to: CGPoint(x: x0, y: y0 + radius))
        path.addQuadCurve(to: CGPoint(x: x0 + radius, y: y0), control: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x0 + length, y: y0))
        path.move(to: CGPoint(x: x1 - length, y: y0))
        path.addLine(to: CGPoint(x: x1 - radius, y: y0))
        path.addQuadCurve(to: CGPoint(x: x1, y: y0 + radius), control: CGPoint(x: x1, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0 + length))
        path.move(to: CGPoint(x: x1, y: y1 - length))
        path.addLine(to: CGPoint(x: x1, y: y1 - radius))
        path.addQuadCurve(to: CGPoint(x: x1 - radius, y: y1), control: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x1 - length, y: y1))
        path.move(to: CGPoint(x: x0 + length, y: y1))
        path.addLine(to: CGPoint(x: x0 + radius, y: y1))
        path.addQuadCurve(to: CGPoint(x: x0, y: y1 - radius), control: CGPoint(x: x0, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1 - length))
        return path
    }
}
