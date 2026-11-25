//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

/// While the session and camera start: the capture screen with an empty window, already asking
/// the visitor to stand in front of the iPad, so the camera simply appears in it.
struct LoadingPageView: View {
    @Environment(\.livenessTheme) private var theme
    var referenceImage: UIImage?

    var body: some View {
        GeometryReader { proxy in
            LivenessCaptureScreen(
                step: .stepIn,
                window: LivenessPreviewGeometry.window(
                    in: proxy.size,
                    theme: theme,
                    normalizedOval: LivenessCaptureStyle.nominalOval
                ),
                camera: LivenessCaptureStyle.emptyWindow
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
