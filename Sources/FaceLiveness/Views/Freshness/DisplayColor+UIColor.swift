//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import Amplify
@_spi(PredictionsFaceLiveness) import FaceLivenessStreaming

extension FaceLivenessSession.DisplayColor {
    var uiColor: UIColor {
        return .init(
            red: rgb.red,
            green: rgb.green,
            blue: rgb.blue,
            alpha: 1
        )
    }
}
