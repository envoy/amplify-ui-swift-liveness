import SwiftUI
import UIKit

enum LivenessCaptureMetrics {
    static let headerHeight: CGFloat = 120
    static let headerSpacing: CGFloat = 28
    static let headerMaximumWidth: CGFloat = 640
    static let verticalMargin: CGFloat = 32
    static let horizontalMargin: CGFloat = 48
    static let cornerRadius: CGFloat = 32
    static let maximumCardHeight: CGFloat = 720
    static let minimumCardHeight: CGFloat = 280
    static let referenceImageSize: CGFloat = 72

    static func cardSize(fitting size: CGSize) -> CGSize {
        let aspect = LivenessPreviewGeometry.previewAspectRatio
        let availableHeight = size.height - headerHeight - headerSpacing - 2 * verticalMargin
        let availableWidth = size.width - 2 * horizontalMargin
        let height = max(minimumCardHeight, min(maximumCardHeight, availableHeight, availableWidth / aspect))
        return CGSize(width: (height * aspect).rounded(), height: height.rounded())
    }
}

struct LivenessCaptureLayout<Camera: View, Overlay: View>: View {
    @Environment(\.livenessTheme) private var theme
    let guidance: LivenessGuidance
    let referenceImage: UIImage?
    let camera: (CGSize) -> Camera
    let overlay: (CGSize) -> Overlay

    init(
        guidance: LivenessGuidance,
        referenceImage: UIImage?,
        @ViewBuilder camera: @escaping (CGSize) -> Camera,
        @ViewBuilder overlay: @escaping (CGSize) -> Overlay
    ) {
        self.guidance = guidance
        self.referenceImage = referenceImage
        self.camera = camera
        self.overlay = overlay
    }

    var body: some View {
        GeometryReader { geometry in
            let cardSize = LivenessCaptureMetrics.cardSize(fitting: geometry.size)

            VStack(spacing: LivenessCaptureMetrics.headerSpacing) {
                ZStack {
                    LivenessGuidanceHeader(guidance: guidance)
                        .id(guidance.title + guidance.detail)
                        .transition(.opacity)
                }
                .animation(.easeOut(duration: 0.2), value: guidance.title + guidance.detail)
                .frame(maxWidth: LivenessCaptureMetrics.headerMaximumWidth)
                .frame(height: LivenessCaptureMetrics.headerHeight, alignment: .bottom)

                CameraCard(
                    referenceImage: guidance.showsOval ? nil : referenceImage,
                    size: cardSize,
                    camera: camera(cardSize),
                    overlay: overlay(cardSize)
                )
            }
            .padding(.horizontal, LivenessCaptureMetrics.horizontalMargin)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(Color(theme.background).ignoresSafeArea())
        .onChange(of: guidance.title) { title in
            UIAccessibility.post(notification: .announcement, argument: title)
        }
    }
}

extension LivenessCaptureLayout where Overlay == EmptyView {
    init(
        guidance: LivenessGuidance,
        referenceImage: UIImage?,
        @ViewBuilder camera: @escaping (CGSize) -> Camera
    ) {
        self.init(guidance: guidance, referenceImage: referenceImage, camera: camera) { _ in EmptyView() }
    }
}

private struct CameraCard<Camera: View, Overlay: View>: View {
    let referenceImage: UIImage?
    let size: CGSize
    let camera: Camera
    let overlay: Overlay

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: LivenessCaptureMetrics.cornerRadius, style: .continuous)
        let thumbnailInset = LivenessCaptureMetrics.referenceImageSize / 2 + 16

        ZStack {
            Color.black
                .clipShape(shape)
            camera
                .frame(width: size.width, height: size.height)
                .clipShape(shape)
            overlay
                .frame(width: size.width, height: size.height)

            if let referenceImage {
                Image(uiImage: referenceImage)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: LivenessCaptureMetrics.referenceImageSize,
                        height: LivenessCaptureMetrics.referenceImageSize
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .offset(x: size.width / 2 - thumbnailInset, y: size.height / 2 - thumbnailInset)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .animation(.easeOut(duration: 0.35), value: referenceImage == nil)
        .frame(width: size.width, height: size.height)
    }
}
