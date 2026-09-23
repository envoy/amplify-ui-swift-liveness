//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI
import Combine
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

struct InstructionContainerView: View {
    @ObservedObject var viewModel: FaceLivenessDetectionViewModel

    var body: some View {
        Text(instruction)
            .font(.custom("SofiaPro-Bold", size: 24))
            .foregroundColor(Color(red: 48 / 255, green: 53 / 255, blue: 65 / 255))
            .multilineTextAlignment(.center)
            .animation(.easeOut(duration: 0.18), value: instruction)
            .accessibilityLabel(instruction)
    }

    private var instruction: String {
        switch viewModel.livenessState.state {
        case .awaitingFaceInOvalMatch(.faceTooClose, _):
            return LocalizedStrings.challenge_instruction_move_face_back
        case .awaitingFaceInOvalMatch(let reason, _),
             .pendingFacePreparedConfirmation(let reason):
            return reason == .pendingCheck
                ? LocalizedStrings.preview_center_your_face_text
                : reason.localizedValue
        case .recording(ovalDisplayed: true):
            return LocalizedStrings.challenge_instruction_move_face_closer
        case .faceMatched, .displayingFreshness:
            return LocalizedStrings.challenge_instruction_hold_still
        case .completedNoLightCheck, .completedDisplayingFreshness:
            return LocalizedStrings.challenge_verifying
        default:
            return LocalizedStrings.preview_center_your_face_text
        }
    }
}
