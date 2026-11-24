//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

struct _FaceLivenessDetectionView<VideoView: View>: View {
    let videoView: VideoView
    let referenceImage: UIImage?
    @ObservedObject var viewModel: FaceLivenessDetectionViewModel
    /// Whether the last step asked to move to one side, so that guidance doesn't flicker.
    @State private var isGuidingToSide = false

    init(
        viewModel: FaceLivenessDetectionViewModel,
        referenceImage: UIImage?,
        @ViewBuilder videoView: @escaping () -> VideoView
    ) {
        self.viewModel = viewModel
        self.referenceImage = referenceImage
        self.videoView = videoView()
    }

    var body: some View {
        GeometryReader { proxy in
            let orientation = LivenessOrientation.currentInterfaceOrientation
            // Where the checked crop is now: it moves when the preview is scaled to fit the oval.
            let liveRect = viewModel.cameraViewRect
            let checkedRect = liveRect.isEmpty
                ? LivenessPreviewGeometry.previewRect(fittingIn: proxy.size, cameraIsLandscape: orientation.isLandscape)
                : liveRect
            let oval = ovalOnScreen(in: checkedRect)
            let step = LivenessCaptureStep(state: viewModel.livenessState.state)
                .confirmingTooClose(face: viewModel.faceRect, oval: oval, nearness: nearness)
                .guidingToSide(
                face: viewModel.faceRect,
                target: oval ?? checkedRect,
                wasGuidingToSide: isGuidingToSide
            )
            LivenessCaptureScreen(
                step: step,
                oval: oval,
                face: viewModel.faceRect,
                otherFaces: viewModel.otherFaceRects,
                checkedRect: checkedRect,
                cameraEdge: LivenessCameraEdge.current(in: orientation),
                camera: ZStack {
                    LivenessBackdrop(image: viewModel.backdrop)
                    videoView
                }
            )
            .onChange(of: step.kind) { kind in
                isGuidingToSide = kind.hasPrefix("moveToSide")
            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    /// How close the face is to filling the oval, while the check is waiting for it to.
    private var nearness: Double {
        if case .awaitingFaceInOvalMatch(_, let nearness) = viewModel.livenessState.state {
            return nearness
        }
        return 0
    }

    /// The service's oval on screen while the check shows it.
    private func ovalOnScreen(in checkedRect: CGRect) -> CGRect? {
        switch viewModel.livenessState.state {
        case .recording(ovalDisplayed: true), .awaitingFaceInOvalMatch, .faceMatched, .displayingFreshness,
             .completedNoLightCheck, .completedDisplayingFreshness, .completed,
             .awaitingDisconnectEvent, .disconnectEventReceived:
            let oval = viewModel.ovalRect
            guard !oval.isEmpty else { return nil }
            return oval.offsetBy(dx: checkedRect.minX, dy: checkedRect.minY)
        default:
            return nil
        }
    }
}

/// A blurred copy of the camera filling the screen behind the scaled-down preview, so the screen
/// still reads as a camera.
struct LivenessBackdrop: View {
    let image: CGImage?

    var body: some View {
        GeometryReader { proxy in
            if let image {
                Image(decorative: image, scale: 1)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .blur(radius: 28)
                    .clipped()
            }
        }
        .accessibilityHidden(true)
    }
}
