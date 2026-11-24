import SwiftUI
import UIKit

/// The capture screen: the camera filling the screen, the guides on it, the instruction at the
/// bottom, the light bar round it all, and the back button.
struct LivenessCaptureScreen<Camera: View>: View {
    let step: LivenessCaptureStep
    /// The service's oval on screen, once it is shown.
    let oval: CGRect?
    let face: CGRect?
    let otherFaces: [CGRect]
    /// The part of the camera the service checks, on screen.
    let checkedRect: CGRect
    let cameraEdge: LivenessCameraEdge
    let camera: Camera

    @State private var stepStart = Date()
    @State private var barStart = Date()

    var body: some View {
        GeometryReader { proxy in
            let barWidth = step == .tooDark
                ? LivenessCaptureStyle.brightLightBarWidth
                : LivenessCaptureStyle.lightBarWidth
            ZStack(alignment: .topLeading) {
                Color.black
                camera
                    .frame(width: proxy.size.width, height: proxy.size.height)
                LivenessFaceGuides(
                    step: step,
                    oval: oval,
                    face: face,
                    otherFaces: otherFaces,
                    checkedRect: checkedRect,
                    start: stepStart
                )
                .frame(width: proxy.size.width, height: proxy.size.height)
                LivenessCaption(title: step.title, barWidth: barWidth)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                LivenessLightBar(edge: cameraEdge, width: barWidth, start: barStart)
                .frame(width: proxy.size.width, height: proxy.size.height)
                LivenessBackButton(barWidth: barWidth)
            }
        }
        .ignoresSafeArea()
        .onChange(of: step.kind) { _ in
            stepStart = Date()
        }
        .onChange(of: step.title) { title in
            UIAccessibility.post(notification: .announcement, argument: title)
        }
    }
}

/// The instruction, white on a shade that darkens toward the bottom of the screen.
struct LivenessCaption: View {
    @Environment(\.livenessTheme) private var theme
    let title: String
    let barWidth: CGFloat

    var body: some View {
        let font = theme.titleFont
        let lineHeight = font.pointSize * LivenessCaptureStyle.titleLineHeightMultiple
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            ZStack(alignment: .bottom) {
                LinearGradient(
                    stops: [
                        .init(color: LivenessCaptureStyle.captionShade.opacity(0), location: 0),
                        .init(color: LivenessCaptureStyle.captionShade.opacity(0.5), location: 0.5),
                        .init(color: LivenessCaptureStyle.captionShade.opacity(0.78), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: LivenessCaptureStyle.captionShadeHeight)

                Text(title)
                    .font(Font(font as CTFont))
                    .kerning(font.pointSize * LivenessCaptureStyle.titleTracking)
                    .lineSpacing(max(lineHeight - font.lineHeight, 0))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .shadow(color: Color.black.opacity(0.28), radius: 8, x: 0, y: 1)
                    .id(title)
                    .transition(.opacity)
                    .padding(.horizontal, LivenessCaptureStyle.captionInset)
                    .padding(.bottom, barWidth + LivenessCaptureStyle.captionGap)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            .animation(.easeOut(duration: 0.2), value: title)
        }
    }
}

/// The app's back button, translucent dark with a white arrow so it reads over any image, just
/// inside the light bar's corner.
struct LivenessBackButton: View {
    @Environment(\.livenessBackAction) private var action
    let barWidth: CGFloat

    var body: some View {
        if let action {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: LivenessCaptureStyle.backButtonCornerRadius, style: .circular)
                        .fill(LivenessCaptureStyle.backButtonFill)
                    Path { path in
                        path.move(to: CGPoint(x: 28, y: 13))
                        path.addLine(to: CGPoint(x: 2, y: 13))
                        path.move(to: CGPoint(x: 13, y: 2))
                        path.addLine(to: CGPoint(x: 2, y: 13))
                        path.addLine(to: CGPoint(x: 13, y: 24))
                    }
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .frame(width: 30, height: 26)
                }
                .frame(width: LivenessCaptureStyle.backButtonSize, height: LivenessCaptureStyle.backButtonSize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Back"))
            .offset(
                x: barWidth + LivenessCaptureStyle.backButtonInset,
                y: barWidth + LivenessCaptureStyle.backButtonInset
            )
            .animation(.easeInOut(duration: 0.3), value: barWidth)
        }
    }
}
