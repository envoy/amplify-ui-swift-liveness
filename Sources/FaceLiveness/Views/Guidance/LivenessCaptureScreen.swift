import SwiftUI
import UIKit

/// The capture screen in the host's page style: the camera seen through an oval window on the
/// page, the ring round the window that fills as the face does, and the instruction under it.
struct LivenessCaptureScreen<Camera: View>: View {
    @Environment(\.livenessTheme) private var theme
    let step: LivenessCaptureStep
    /// The camera window on screen: the service's oval once it is shown, else where it will be.
    let window: CGRect
    let camera: Camera

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                camera
                    .frame(width: proxy.size.width, height: proxy.size.height)
                LivenessOvalCutout(oval: window)
                    .fill(Color(theme.backgroundColor), style: FillStyle(eoFill: true))
                LivenessRing(window: window, progress: step.ringProgress, accent: Color(theme.accentColor))
                LivenessCaption(title: step.title, top: window.maxY + LivenessCaptureStyle.ringOutset)
            }
        }
        .ignoresSafeArea()
        .onChange(of: step.title) { title in
            UIAccessibility.post(notification: .announcement, argument: title)
        }
    }
}

/// The ring round the camera window, clear of it by `ringGap`: a light track, and the
/// location's colour filling both sides from the chin up.
struct LivenessRing: View {
    let window: CGRect
    let progress: Double
    let accent: Color

    var body: some View {
        let inset = -LivenessCaptureStyle.ringOutset
        let ring = window.insetBy(dx: inset, dy: inset)
        ZStack(alignment: .topLeading) {
            LivenessOvalOutline(oval: ring)
                .stroke(LivenessCaptureStyle.track, lineWidth: LivenessCaptureStyle.ringWidth)
            ForEach([true, false], id: \.self) { left in
                LivenessHalfOval(oval: ring, left: left)
                    .trim(from: 0, to: progress)
                    .stroke(accent, style: StrokeStyle(lineWidth: LivenessCaptureStyle.ringWidth, lineCap: .round))
                    .opacity(progress > 0 ? 1 : 0)
            }
            .animation(.easeOut(duration: 0.3), value: progress)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The instruction, in the host's page title style, centred under the ring.
struct LivenessCaption: View {
    @Environment(\.livenessTheme) private var theme
    let title: String
    /// The bottom of the ring.
    let top: CGFloat

    var body: some View {
        let font = theme.titleFont
        Text(title)
            .font(Font(font as CTFont))
            .lineSpacing(max(theme.titleLineHeight - font.lineHeight, 0))
            .foregroundColor(Color(theme.titleColor))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .id(title)
            .transition(.opacity)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, LivenessCaptureStyle.captionInset)
            .padding(.top, top + LivenessCaptureStyle.captionGap)
            .animation(.easeOut(duration: 0.2), value: title)
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// The screen with an oval hole, filled even-odd so only the page round the window is drawn.
struct LivenessOvalCutout: Shape {
    var oval: CGRect

    var animatableData: CGRect.AnimatableData {
        get { oval.animatableData }
        set { oval.animatableData = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path(rect.insetBy(dx: -2, dy: -2))
        path.addEllipse(in: oval)
        return path
    }
}

/// An oval at a fixed place on the screen, which animates with the window.
struct LivenessOvalOutline: Shape {
    var oval: CGRect

    var animatableData: CGRect.AnimatableData {
        get { oval.animatableData }
        set { oval.animatableData = newValue }
    }

    func path(in _: CGRect) -> Path {
        Path(ellipseIn: oval)
    }
}

/// One side of the oval, from the bottom up to the top, so progress fills from the chin up.
struct LivenessHalfOval: Shape {
    var oval: CGRect
    let left: Bool

    var animatableData: CGRect.AnimatableData {
        get { oval.animatableData }
        set { oval.animatableData = newValue }
    }

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
