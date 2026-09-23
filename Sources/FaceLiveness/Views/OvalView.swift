//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

class OvalView: UIView {
    let ovalFrame: CGRect

    init(frame: CGRect, ovalFrame: CGRect) {
        self.ovalFrame = ovalFrame
        super.init(frame: frame)
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        let oval = UIBezierPath(ovalIn: ovalFrame)
        UIColor.white.withAlphaComponent(0.92).setStroke()
        oval.lineWidth = 5
        oval.stroke()
    }

    required init?(coder: NSCoder) { nil }
}
