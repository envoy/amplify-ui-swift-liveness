//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import AVFoundation
import AWSPredictionsPlugin

struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var faceLivenessDetectionViewModel: FaceLivenessDetectionViewModel

    init(
        faceLivenessDetectionViewModel: FaceLivenessDetectionViewModel
    ) {
        self.faceLivenessDetectionViewModel = faceLivenessDetectionViewModel
    }

    func makeUIViewController(
        context: Context
    ) -> _LivenessViewController {
        let livenessViewController = _LivenessViewController(
            viewModel: faceLivenessDetectionViewModel
        )
        livenessViewController.theme = context.environment.livenessTheme
        return livenessViewController
    }

    func updateUIViewController(
        _ uiViewController: _LivenessViewController,
        context: Context
    ) {
        uiViewController.theme = context.environment.livenessTheme
        uiViewController.updateCameraOrientation()
    }
}
