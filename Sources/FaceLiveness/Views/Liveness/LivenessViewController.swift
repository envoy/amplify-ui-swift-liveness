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
@_spi(PredictionsFaceLiveness) import AWSPredictionsPlugin

final class _LivenessViewController: UIViewController {
    let viewModel: FaceLivenessDetectionViewModel
    var previewLayer: CALayer?

    let faceShapeLayer = CAShapeLayer()
    var ovalExists = false
    var ovalRect: CGRect?
    var freshness = Freshness()
    let freshnessView = FreshnessView()
    var readyForOval = false

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
        let checkedRect = LivenessPreviewGeometry.previewRect(
            fittingIn: view.bounds.size,
            cameraIsLandscape: currentInterfaceOrientation.isLandscape
        )

        // The camera image fills the screen; the service checks its centred 3:4 crop.
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
        avLayer.frame = view.bounds
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

        previewLayer.frame = cameraRect
        if let mask = previewLayer.mask {
            mask.contents = Self.featheredMask(size: cameraRect.size)
            mask.frame = CGRect(origin: .zero, size: cameraRect.size)
        }
        viewModel.cameraViewRect = checkedRect
        viewModel.redrawOvalForCurrentCameraViewRect()
    }

    /// The checked crop and the camera image on screen: the image fills the screen, and once the
    /// service's oval is shown it is scaled down only as far as the oval needs to fit.
    private func currentGeometry() -> (checked: CGRect, camera: CGRect) {
        let isLandscape = currentInterfaceOrientation.isLandscape
        if ovalExists, let oval = viewModel.normalizedOval {
            let checked = LivenessPreviewGeometry.previewRect(
                fittingIn: view.bounds.size,
                cameraIsLandscape: isLandscape,
                placingOval: oval
            )
            return (checked, LivenessPreviewGeometry.cameraRect(aroundPreview: checked, cameraIsLandscape: isLandscape))
        }
        let checked = LivenessPreviewGeometry.previewRect(fittingIn: view.bounds.size, cameraIsLandscape: isLandscape)
        return (checked, view.bounds)
    }

    /// An alpha mask that fades the scaled-down camera image into the blurred backdrop over its
    /// outer 64 pt, so no edge shows where the sharp image ends.
    static func featheredMask(size: CGSize) -> CGImage? {
        guard size.width > 1, size.height > 1 else { return nil }
        let feather = min(64, size.width / 4, size.height / 4)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let steps = Int(feather)
            for step in 0..<steps {
                let inset = CGFloat(step)
                let alpha = CGFloat(step + 1) / CGFloat(steps)
                UIColor(white: 1, alpha: alpha * alpha * (3 - 2 * alpha)).setStroke()
                let ring = UIBezierPath(rect: CGRect(origin: .zero, size: size).insetBy(dx: inset + 0.5, dy: inset + 0.5))
                ring.lineWidth = 1
                ring.stroke()
            }
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size).insetBy(dx: feather, dy: feather))
        }.cgImage
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
                // Scale the image down, if needed, so the oval fits inside the light bar.
                let (checkedRect, cameraRect) = self.currentGeometry()
                CATransaction.begin()
                CATransaction.setAnimationDuration(UIAccessibility.isReduceMotionEnabled ? 0 : 0.45)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(controlPoints: 0.45, 0, 0.2, 1))
                previewLayer.frame = cameraRect
                let mask = CALayer()
                mask.contents = Self.featheredMask(size: cameraRect.size)
                mask.frame = CGRect(origin: .zero, size: cameraRect.size)
                previewLayer.mask = mask
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
