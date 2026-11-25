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
    @Environment(\.livenessTheme) private var theme

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
            // The view controller places the camera so this oval lands exactly on the window.
            let window = LivenessPreviewGeometry.window(
                in: proxy.size,
                theme: theme,
                normalizedOval: (isOvalShown ? viewModel.normalizedOval : nil) ?? LivenessCaptureStyle.nominalOval
            )
            let oval = isOvalShown ? window : nil
            let step = LivenessCaptureStep(state: viewModel.livenessState.state)
                .confirmingTooClose(face: viewModel.faceRect, oval: oval, nearness: nearness)
                .guidingToSide(
                    face: viewModel.faceRect,
                    target: oval ?? viewModel.cameraViewRect,
                    wasGuidingToSide: isGuidingToSide
                )
            LivenessCaptureScreen(step: step, window: window, camera: videoView)
                .animation(LivenessCaptureStyle.windowAnimation, value: isOvalShown)
                .onChange(of: step.isMovingToSide) { isMovingToSide in
                    isGuidingToSide = isMovingToSide
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

    /// Whether the check is showing the service's oval.
    private var isOvalShown: Bool {
        switch viewModel.livenessState.state {
        case .recording(ovalDisplayed: true), .awaitingFaceInOvalMatch, .faceMatched, .displayingFreshness,
             .completedNoLightCheck, .completedDisplayingFreshness, .completed,
             .awaitingDisconnectEvent, .disconnectEventReceived:
            true
        default:
            false
        }
    }
}
