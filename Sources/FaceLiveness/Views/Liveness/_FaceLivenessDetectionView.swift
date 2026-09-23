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
    @Binding var displayResultsView: Bool

    init(
        viewModel: FaceLivenessDetectionViewModel,
        referenceImage: UIImage?,
        @ViewBuilder videoView: @escaping () -> VideoView
    ) {
        self.viewModel = viewModel
        self.referenceImage = referenceImage
        self.videoView = videoView()

        self._displayResultsView = .init(
            get: { viewModel.livenessState.state == .completed },
            set: { _ in }
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(410, geometry.size.height * 0.4, geometry.size.width * 0.56)

            ZStack {
                Color(red: 246 / 255, green: 246 / 255, blue: 249 / 255)

                Text("Take a selfie")
                    .font(.custom("SofiaPro-Bold", size: 36))
                    .foregroundColor(Color(red: 48 / 255, green: 53 / 255, blue: 65 / 255))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 62)

                ZStack {
                    FaceScanProgressRing(
                        progress: progress,
                        diameter: diameter + 84
                    )

                    Circle()
                        .fill(Color(red: 31 / 255, green: 35 / 255, blue: 45 / 255))
                        .frame(width: diameter, height: diameter)
                        .shadow(color: .black.opacity(0.18), radius: 24, y: 14)

                    videoView
                        .frame(width: diameter, height: diameter)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 5))

                    if let referenceImage {
                        Image(uiImage: referenceImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 5)
                            .offset(
                                x: diameter / 2 - 42,
                                y: diameter / 2 - 42
                            )
                    }
                }
                .frame(width: diameter + 84, height: diameter + 84)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                InstructionContainerView(viewModel: viewModel)
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .offset(y: diameter / 2 + 104)

            }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private var progress: Double {
        switch viewModel.livenessState.state {
        case .initial, .pendingFacePreparedConfirmation, .waitForRecording:
            return 0.08
        case .recording(ovalDisplayed: false):
            return 0.12
        case .recording(ovalDisplayed: true):
            return 0.2
        case .awaitingFaceInOvalMatch(_, let percentage):
            return 0.2 + min(max(percentage, 0), 1) * 0.65
        case .faceMatched:
            return 0.92
        case .completedNoLightCheck, .completedDisplayingFreshness, .completed,
             .awaitingDisconnectEvent, .disconnectEventReceived:
            return 1
        default:
            return 0
        }
    }
}

private struct FaceScanProgressRing: View {
    private static let segmentCount = 60
    private static let completionOrder = [0, 59, 1, 58, 2] +
        Array(stride(from: 57, through: 31, by: -1)) +
        Array(stride(from: 30, through: 3, by: -1))

    let progress: Double
    let diameter: CGFloat

    var body: some View {
        let completed = Int(min(max(progress, 0), 1) * Double(Self.segmentCount))
        let innerRadius = diameter / 2 - 29

        ZStack {
            ForEach(0 ..< Self.segmentCount, id: \.self) { index in
                let rank = Self.completionOrder.firstIndex(of: index) ?? index
                let isCompleted = rank < completed
                let lineLength: CGFloat = isCompleted ? 29 : 12

                Capsule()
                    .fill(isCompleted
                        ? Color(red: 30 / 255, green: 204 / 255, blue: 106 / 255)
                        : Color(red: 192 / 255, green: 196 / 255, blue: 203 / 255))
                    .frame(width: 4.5, height: lineLength)
                    .offset(y: -(innerRadius + lineLength / 2))
                    .rotationEffect(.degrees(Double(index) * 6))
                    .animation(.easeOut(duration: 0.22), value: completed)
            }
        }
        .frame(width: diameter, height: diameter)
    }
}
