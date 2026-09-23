//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

struct LoadingPageView: View {

    var body: some View {
        ZStack {
            Color(red: 246 / 255, green: 246 / 255, blue: 249 / 255)
                .ignoresSafeArea()

            ProgressView()
                .tint(Color(red: 63 / 255, green: 68 / 255, blue: 80 / 255))
                .scaleEffect(1.35)
        }
    }
}

struct LoadingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingPageView()
    }
}
