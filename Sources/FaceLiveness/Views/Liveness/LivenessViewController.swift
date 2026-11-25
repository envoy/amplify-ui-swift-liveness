//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AVFoundation
import Vision
import Amplify
@_spi(PredictionsFaceLiveness) import FaceLivenessStreaming

final class _LivenessViewController: UIViewController {
    let viewModel: FaceLivenessDetectionViewModel
    var previewLayer: CALayer?

    let faceShapeLayer = CAShapeLayer()
    var ovalExists = false
    var ovalRect: CGRect?
    var freshness = Freshness()
    let freshnessView = FreshnessView()
    var readyForOval = false
    /// The host's page layout, which places the camera window.
    var theme = FaceLivenessTheme() {
        didSet {
            guard theme != oldValue, isViewLoaded else { return }
            view.setNeedsLayout()
        }
    }

    init(
        viewModel: FaceLivenessDetectionViewModel
    ) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.livenessViewControllerDelegate = self
        viewModel.normalizeFace = { [weak viewModel] face in
            // the same fitted rect the preview and the oval use; lock-guarded, so no main hop
            guard let previewRect = viewModel?.cameraViewRect else { return face }
            return face.normalize(width: previewRect.width, height: previewRect.height)
        }
    }
    
    deinit {
        guard let previewLayer = self.previewLayer else { return }
        previewLayer.removeFromSuperlayer()
        (previewLayer as? AVCaptureVideoPreviewLayer)?.session = nil
        self.previewLayer = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        layoutSubviews()
        setupAVLayer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGeometryForCurrentViewSize()
    }

    private func layoutSubviews() {
        freshnessView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(freshnessView)
        NSLayoutConstraint.activate([
            freshnessView.topAnchor.constraint(equalTo: view.topAnchor),
            freshnessView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            freshnessView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            freshnessView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        freshnessView.clearColors()
    }

    private func setupAVLayer() {
        guard previewLayer == nil else { return }
        let (checkedRect, cameraRect) = currentGeometry()

        guard let avLayer = viewModel.configureCamera(
            withinFrame: view.bounds,
            interfaceOrientation: currentInterfaceOrientation
        ) else {
            DispatchQueue.main.async { [weak self] in
                self?.viewModel.livenessState
                    .unrecoverableStateEncountered(.missingVideoPermission)
            }
            return
        }

        // `viewDidLayoutSubviews` takes over on resize
        avLayer.frame = cameraRect
        self.previewLayer = avLayer
        viewModel.cameraViewRect = checkedRect

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.layer.insertSublayer(avLayer, at: 0)
            self.view.layoutIfNeeded()

            self.viewModel.startSession()
        }
    }

    /// Re-fits the preview layer and the oval to the view's current size. Skipped while the
    /// fitted rect is unchanged (which also stops the layout pass recursing) or has no area.
    private func updateGeometryForCurrentViewSize() {
        updateCameraOrientation()
        guard let previewLayer = self.previewLayer else { return }

        let (checkedRect, cameraRect) = currentGeometry()
        guard !checkedRect.isEmpty,
              checkedRect != viewModel.cameraViewRect || previewLayer.frame != cameraRect
        else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = cameraRect
        CATransaction.commit()
        viewModel.cameraViewRect = checkedRect
        viewModel.redrawOvalForCurrentCameraViewRect()
    }

    /// The checked crop and the camera image on screen, placed so the oval lands on the camera
    /// window: the service's oval once it is shown, before that one of the usual proportions.
    private func currentGeometry() -> (checked: CGRect, camera: CGRect) {
        let oval = (ovalExists ? viewModel.normalizedOval : nil) ?? LivenessCaptureStyle.nominalOval
        let window = LivenessPreviewGeometry.window(in: view.bounds.size, theme: theme, normalizedOval: oval)
        let checked = LivenessPreviewGeometry.previewRect(placing: oval, on: window)
        let camera = LivenessPreviewGeometry.cameraRect(
            aroundPreview: checked,
            cameraIsLandscape: currentInterfaceOrientation.isLandscape
        )
        return (checked, camera)
    }

    func updateCameraOrientation() {
        viewModel.updateCameraOrientation(currentInterfaceOrientation)
    }

    private var currentInterfaceOrientation: UIInterfaceOrientation {
        view.window?.windowScene?.interfaceOrientation
            ?? LivenessOrientation.currentInterfaceOrientation
    }

    var runningFreshness = false
    var hasSentClientInformationEvent = false
    var challengeID = UUID().uuidString
    var initialFace: FaceDetection?
    var videoStartTimeStamp: UInt64?
    var faceMatchStartTime: UInt64?
    var freshnessEventsComplete = false
    var videoSentCount = 0
    var hasSentFinalEvent = false
    var hasSentEmptyFinalVideoEvent = false
    var ovalView: OvalView?


    required init?(coder: NSCoder) { fatalError() }
}

extension _LivenessViewController: FaceLivenessViewControllerPresenter {
    func displaySingleFrame(uiImage _: UIImage) {
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.stopRecording()
        }
    }

    func displayFreshness(colorSequences: [FaceLivenessSession.DisplayColor]) {
        self.ovalView?.setNeedsDisplay()
        DispatchQueue.main.async { [weak self] in
            self?.viewModel.livenessState.displayingFreshness()
        }
        self.freshness.showColorSequences(
            colorSequences,
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height,
            view: self.freshnessView,
            onNewColor: { [weak self] colorEvent in
                self?.viewModel.sendColorDisplayedEvent(colorEvent)
            },
            onComplete: { [weak self] in
                guard let self else { return }
                self.freshnessView.removeFromSuperview()

                self.viewModel.handleFreshnessComplete()
            }
        )
    }

    func stopFreshness() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.freshness.cancel()
            // Clear the colors but leave the view in the hierarchy so that, if the face
            // returns and re-matches, `displayFreshness(colorSequences:)` can restart the
            // flash on the same view.
            self.freshnessView.clearColors()
        }
    }

    func drawOvalInCanvas(_ ovalRect: CGRect) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.ovalView?.removeFromSuperview()
            self.ovalView = nil
            let isFirstOval = !self.ovalExists
            self.ovalExists = true
            if isFirstOval, let previewLayer = self.previewLayer {
                // Move the image so the service's oval lands on the window, as the window takes its shape.
                let (checkedRect, cameraRect) = self.currentGeometry()
                CATransaction.begin()
                CATransaction.setAnimationDuration(
                    UIAccessibility.isReduceMotionEnabled ? 0 : LivenessCaptureStyle.windowAnimationDuration
                )
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.45, 0, 0.2, 1))
                previewLayer.frame = cameraRect
                CATransaction.commit()
                self.viewModel.cameraViewRect = checkedRect
                self.viewModel.refitOvalToCameraViewRect()
            }
            self.ovalRect = isFirstOval ? self.viewModel.ovalRect : ovalRect
        }
    }
    
    func completeNoLightCheck() {
        self.viewModel.completeNoLightCheck()
    }
}
