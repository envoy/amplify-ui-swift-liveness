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

        LivenessCaptureLayout(guidance: guidance, referenceImage: referenceImage) { _ in
            videoView
        } overlay: { size in
            ZStack {
                if guidance.showsOval, let oval = ovalGuideRect(fitting: size) {
                    OvalGuide(oval: oval, guidance: guidance)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.35), value: guidance.showsOval)
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func ovalGuideRect(fitting size: CGSize) -> CGRect? {
        let oval = viewModel.ovalRect
        guard !oval.isEmpty else { return nil }
        let preview = LivenessPreviewGeometry.previewRect(fittingIn: size)
        return oval.offsetBy(dx: preview.minX, dy: preview.minY)
    }
}
