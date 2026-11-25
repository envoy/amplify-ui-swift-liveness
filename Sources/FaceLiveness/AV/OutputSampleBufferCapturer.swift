//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AVFoundation
import CoreImage

class OutputSampleBufferCapturer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let faceDetector: FaceDetector
    let videoChunker: VideoChunker
    private let frameProcessor = LivenessFrameProcessor()

    init(faceDetector: FaceDetector, videoChunker: VideoChunker) {
        self.faceDetector = faceDetector
        self.videoChunker = videoChunker
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let sourceBuffer = sampleBuffer.imageBuffer,
              let imageBuffer = frameProcessor.portraitBuffer(from: sourceBuffer)
        else { return }

        videoChunker.consume(
            imageBuffer,
            presentationTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        )
        faceDetector.detectFaces(from: imageBuffer)
    }
}

private final class LivenessFrameProcessor {
    private static let targetSize = CGSize(width: 480, height: 640)
    private let context = CIContext(options: [.cacheIntermediates: false])
    private let pool: CVPixelBufferPool?

    init() {
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: Int(Self.targetSize.width),
            kCVPixelBufferHeightKey as String: Int(Self.targetSize.height),
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        var createdPool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(nil, nil, attributes as CFDictionary, &createdPool)
        pool = createdPool
    }

    func portraitBuffer(from sourceBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let sourceWidth = CVPixelBufferGetWidth(sourceBuffer)
        let sourceHeight = CVPixelBufferGetHeight(sourceBuffer)
        guard sourceWidth != Int(Self.targetSize.width) ||
                sourceHeight != Int(Self.targetSize.height)
        else { return sourceBuffer }

        guard let pool else { return nil }
        var destinationBuffer: CVPixelBuffer?
        guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &destinationBuffer) == kCVReturnSuccess,
              let destinationBuffer
        else { return nil }

        let source = CIImage(cvPixelBuffer: sourceBuffer)
        let scale = max(
            Self.targetSize.width / source.extent.width,
            Self.targetSize.height / source.extent.height
        )
        let scaled = source.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let crop = CGRect(
            x: scaled.extent.midX - Self.targetSize.width / 2,
            y: scaled.extent.midY - Self.targetSize.height / 2,
            width: Self.targetSize.width,
            height: Self.targetSize.height
        )
        let portrait = scaled
            .cropped(to: crop)
            .transformed(by: CGAffineTransform(translationX: -crop.minX, y: -crop.minY))

        context.render(
            portrait,
            to: destinationBuffer,
            bounds: CGRect(origin: .zero, size: Self.targetSize),
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return destinationBuffer
    }
}
