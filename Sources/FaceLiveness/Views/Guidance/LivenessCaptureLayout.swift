import SwiftUI
import UIKit

enum LivenessCaptureMetrics {
    static let ringGap: CGFloat = 22
    static let ringWidth: CGFloat = 12

    static func diameter(fitting size: CGSize) -> CGFloat {
        max(200, min(460, size.width * 0.6, size.height - 360 - 2 * ringGap))
    }
}

struct LivenessCaptureLayout<Camera: View>: View {
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

            VStack(spacing: 0) {
                ZStack {
                    LivenessGuidanceHeader(guidance: guidance)
                        .id(guidance.title + guidance.detail)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 16)),
                            removal: .opacity
                        ))
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: guidance.title + guidance.detail)
                .frame(maxWidth: 760)
                .padding(.top, 56)
                .padding(.horizontal, 40)

                Spacer(minLength: 24)

                FaceStage(
                    guidance: guidance,
                    referenceImage: referenceImage,
                    diameter: diameter,
                    camera: camera(diameter)
                )

                Spacer(minLength: 48)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(LivenessStyle.background.ignoresSafeArea())
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
        let ringDiameter = diameter + 2 * LivenessCaptureMetrics.ringGap

        ZStack {
            FaceFillRing(progress: guidance.progress, lineWidth: LivenessCaptureMetrics.ringWidth)
                .frame(width: ringDiameter, height: ringDiameter)

            Circle()
                .fill(LivenessStyle.cameraBackdrop)
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.18), radius: 24, y: 14)

            ZStack {
                camera
                if guidance.isComplete {
                    CompletionMark(diameter: diameter)
                }
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 5))
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: guidance.isComplete)

            if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 74, height: 74)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 5)
                    .offset(x: diameter / 2 - 42, y: diameter / 2 - 42)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: ringDiameter, height: ringDiameter)
    }
}
