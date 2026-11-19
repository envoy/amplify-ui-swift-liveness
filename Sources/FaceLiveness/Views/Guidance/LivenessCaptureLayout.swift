import SwiftUI
import UIKit

enum LivenessCaptureMetrics {
    static let ringGap: CGFloat = 14
    static let ringWidth: CGFloat = 8
    static let headerHeight: CGFloat = 132
    static let headerSpacing: CGFloat = 40
    static let headerMaximumWidth: CGFloat = 620
    static let contentCenterYOffset: CGFloat = -38

    static func diameter(fitting size: CGSize) -> CGFloat {
        max(200, min(520, size.width - 192, size.height - 2 * headerHeight - 2 * ringGap - 96))
    }
}

struct LivenessCaptureLayout<Camera: View>: View {
    @Environment(\.livenessTheme) private var theme
    let guidance: LivenessGuidance
    let referenceImage: UIImage?
    let camera: (CGFloat) -> Camera

    init(
        guidance: LivenessGuidance,
        referenceImage: UIImage?,
        @ViewBuilder camera: @escaping (CGFloat) -> Camera
    ) {
        self.guidance = guidance
        self.referenceImage = referenceImage
        self.camera = camera
    }

    var body: some View {
        GeometryReader { geometry in
            let diameter = LivenessCaptureMetrics.diameter(fitting: geometry.size)
            let stageDiameter = diameter + 2 * LivenessCaptureMetrics.ringGap
            let headerBlock = LivenessCaptureMetrics.headerHeight + LivenessCaptureMetrics.headerSpacing
            let stageTop = (geometry.size.height - stageDiameter + headerBlock) / 2
                + LivenessCaptureMetrics.contentCenterYOffset

            ZStack(alignment: .top) {
                ZStack {
                    LivenessGuidanceHeader(guidance: guidance)
                        .id(guidance.title + guidance.detail)
                        .transition(.opacity)
                }
                .animation(.easeOut(duration: 0.2), value: guidance.title + guidance.detail)
                .frame(maxWidth: LivenessCaptureMetrics.headerMaximumWidth)
                .frame(
                    width: geometry.size.width,
                    height: max(0, stageTop - LivenessCaptureMetrics.headerSpacing),
                    alignment: .bottom
                )

                FaceStage(
                    guidance: guidance,
                    referenceImage: referenceImage,
                    diameter: diameter,
                    camera: camera(diameter)
                )
                .offset(y: stageTop)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .background(Color(theme.background).ignoresSafeArea())
        .onChange(of: guidance.title) { title in
            UIAccessibility.post(notification: .announcement, argument: title)
        }
    }
}

private struct FaceStage<Camera: View>: View {
    let guidance: LivenessGuidance
    let referenceImage: UIImage?
    let diameter: CGFloat
    let camera: Camera

    var body: some View {
        let stageDiameter = diameter + 2 * LivenessCaptureMetrics.ringGap

        ZStack {
            FaceFillRing(
                progress: guidance.progress,
                isMatched: guidance.isMatched,
                lineWidth: LivenessCaptureMetrics.ringWidth
            )
            .frame(width: stageDiameter, height: stageDiameter)

            ZStack {
                Color.black
                camera
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())

            if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: diameter / 2 - 40, y: diameter / 2 - 40)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: stageDiameter, height: stageDiameter)
    }
}
