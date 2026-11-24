//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// Where the camera image and the part of it the service checks sit on screen.
///
/// The preview fills the whole screen. The frames sent to the service are the centred 3:4 portrait
/// crop of the camera image (`LivenessFrameProcessor` scales the 4:3 VGA frame to fill 480 × 640),
/// so faces and the service's oval are measured in that crop's rect on screen.
enum LivenessPreviewGeometry {
    /// Width / height of the frames the service checks.
    static let previewAspectRatio: CGFloat = 3.0 / 4.0
    /// Width / height of the VGA camera image in landscape.
    static let landscapeCameraAspectRatio: CGFloat = 4.0 / 3.0

    /// The camera image filling `viewport`, centred; parts past the edges are cut off.
    static func cameraRect(fillingViewport viewport: CGSize, cameraIsLandscape: Bool) -> CGRect {
        guard viewport.width > 0, viewport.height > 0 else { return .zero }

        let aspect = cameraIsLandscape ? landscapeCameraAspectRatio : 1 / landscapeCameraAspectRatio
        let scale = max(viewport.width / aspect, viewport.height)
        let size = CGSize(width: aspect * scale, height: scale)
        return CGRect(
            x: (viewport.width - size.width) / 2,
            y: (viewport.height - size.height) / 2,
            width: size.width,
            height: size.height
        )
    }

    /// The centred 3:4 crop of the camera image that the service checks, on screen.
    static func previewRect(fittingIn viewport: CGSize, cameraIsLandscape: Bool) -> CGRect {
        let camera = cameraRect(fillingViewport: viewport, cameraIsLandscape: cameraIsLandscape)
        guard !camera.isEmpty else { return .zero }

        let size: CGSize
        if camera.width / camera.height > previewAspectRatio {
            size = CGSize(width: camera.height * previewAspectRatio, height: camera.height)
        } else {
            size = CGSize(width: camera.width, height: camera.width / previewAspectRatio)
        }
        return CGRect(
            x: camera.midX - size.width / 2,
            y: camera.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    /// The room the oval has: inside the light bar, and above the one-line instruction, with a
    /// 24 pt margin to each.
    static func ovalBand(in viewport: CGSize) -> CGRect {
        let bar = LivenessCaptureStyle.lightBarWidth
        let margin: CGFloat = 24
        let caption = LivenessCaptureStyle.captionGap + LivenessCaptureStyle.titleSize * LivenessCaptureStyle.titleLineHeightMultiple
        return CGRect(
            x: bar + margin,
            y: bar + margin,
            width: viewport.width - 2 * (bar + margin),
            height: viewport.height - (bar + margin) - (bar + caption + margin)
        )
    }

    /// Where the checked crop sits once the service's oval is known. The camera keeps filling the
    /// screen when the oval fits between the light bar and the instruction. When it doesn't (the
    /// service's oval can be most of the frame), the image is scaled down just enough, about the
    /// oval's centre, and moved so the oval sits inside that room; a blurred copy of the camera
    /// fills the edges. The camera itself is never zoomed, so the face on screen grows exactly as
    /// the visitor leans in. `normalizedOval` is the oval as fractions of the checked frame.
    static func previewRect(
        fittingIn viewport: CGSize,
        cameraIsLandscape: Bool,
        placingOval normalizedOval: CGRect
    ) -> CGRect {
        let cover = previewRect(fittingIn: viewport, cameraIsLandscape: cameraIsLandscape)
        guard !cover.isEmpty, normalizedOval.width > 0, normalizedOval.height > 0 else { return cover }

        func oval(in crop: CGRect) -> CGRect {
            CGRect(
                x: crop.minX + normalizedOval.minX * crop.width,
                y: crop.minY + normalizedOval.minY * crop.height,
                width: normalizedOval.width * crop.width,
                height: normalizedOval.height * crop.height
            )
        }

        let band = ovalBand(in: viewport)
        let natural = oval(in: cover)
        let scale = min(1, band.height / natural.height, band.width / natural.width)
        var crop = CGRect(
            x: natural.midX - (natural.midX - cover.minX) * scale,
            y: natural.midY - (natural.midY - cover.minY) * scale,
            width: cover.width * scale,
            height: cover.height * scale
        )

        let placed = oval(in: crop)
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        if placed.minX < band.minX { dx = band.minX - placed.minX } else if placed.maxX > band.maxX { dx = band.maxX - placed.maxX }
        if placed.minY < band.minY { dy = band.minY - placed.minY } else if placed.maxY > band.maxY { dy = band.maxY - placed.maxY }
        crop = crop.offsetBy(dx: dx, dy: dy)
        return crop
    }

    /// The whole camera image around a checked crop: the crop is its centred 3:4 part.
    static func cameraRect(aroundPreview preview: CGRect, cameraIsLandscape: Bool) -> CGRect {
        guard cameraIsLandscape else { return preview }
        let width = preview.height * landscapeCameraAspectRatio
        return CGRect(x: preview.midX - width / 2, y: preview.minY, width: width, height: preview.height)
    }

    /// Scales the service's oval from video coordinates to a preview `previewWidth` wide. The
    /// result is relative to the preview's origin.
    static func ovalRect(
        forVideoOval videoOval: CGRect,
        videoSize: CGSize,
        previewWidth: CGFloat
    ) -> CGRect {
        guard videoSize.width > 0 else { return .zero }

        let scaleRatio = previewWidth / videoSize.width

        return CGRect(
            x: videoOval.minX * scaleRatio,
            y: videoOval.minY * scaleRatio,
            width: videoOval.width * scaleRatio,
            height: videoOval.height * scaleRatio
        )
    }
}
