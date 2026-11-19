//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import UIKit

struct LoadingPageView: View {
    var referenceImage: UIImage?

    var body: some View {
        LivenessCaptureLayout(guidance: .gettingReady, referenceImage: referenceImage) { _ in
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.6)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct LoadingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPageView()
    }
}
