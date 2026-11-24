//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// While the session and camera start: the capture screen over black, already asking the
/// visitor to stand in front of the iPad, so the image simply appears under it.
struct LoadingPageView: View {
    var referenceImage: UIImage?

    var body: some View {
        GeometryReader { proxy in
            let orientation = LivenessOrientation.currentInterfaceOrientation
            LivenessCaptureScreen(
                step: .stepIn,
                oval: nil,
                face: nil,
                otherFaces: [],
                checkedRect: LivenessPreviewGeometry.previewRect(
                    fittingIn: proxy.size,
                    cameraIsLandscape: orientation.isLandscape
                ),
                cameraEdge: LivenessCameraEdge.current(in: orientation),
                camera: Color.black
            )
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoadingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPageView()
    }
}
