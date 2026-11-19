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
        let guidance = LivenessGuidance(state: viewModel.livenessState.state)

        LivenessCaptureLayout(guidance: guidance, referenceImage: referenceImage) { diameter in
            ZStack {
                videoView

                if guidance.showsOval, let oval = ovalGuideRect(diameter: diameter) {
                    OvalGuide(oval: oval, guidance: guidance)
                        .transition(.opacity.combined(with: .scale(scale: 1.15)))
                }
            }
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: guidance.showsOval)
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func ovalGuideRect(diameter: CGFloat) -> CGRect? {
        let oval = viewModel.ovalRect
        guard !oval.isEmpty else { return nil }
        let preview = LivenessPreviewGeometry.previewRect(
            fittingIn: CGSize(width: diameter, height: diameter)
        )
        return oval.offsetBy(dx: preview.minX, dy: preview.minY)
    }
}
