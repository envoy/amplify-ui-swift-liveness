//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics
import UIKit

/// Where the camera image and the part of it the service checks sit on screen.
///
/// The frames sent to the service are the centred 3:4 portrait crop of the camera image (`LivenessFrameProcessor` scales the 4:3 VGA frame to fill 480 × 640),
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

    /// The camera window on screen for an oval of `normalizedOval`'s proportions: centred across
    /// the screen, and centred down it together with the ring and one line of instruction, inside
    /// the theme's insets. It is as tall as the room allows, up to `LivenessCaptureStyle`'s limits.
    static func window(in viewport: CGSize, theme: FaceLivenessTheme, normalizedOval: CGRect) -> CGRect {
        guard viewport.width > 0, viewport.height > 0, normalizedOval.width > 0, normalizedOval.height > 0 else {
            return .zero
        }
        let outset = LivenessCaptureStyle.ringOutset
        let insets = theme.contentInsets
        let caption = LivenessCaptureStyle.captionGap + theme.titleLineHeight
        let room = CGRect(
            x: insets.left,
            y: insets.top,
            width: viewport.width - insets.left - insets.right,
            height: viewport.height - insets.top - insets.bottom
        )
        // Width / height of the oval on screen: the checked frame is 3:4.
        let aspect = normalizedOval.width / normalizedOval.height * previewAspectRatio
        let height = max(0, min(
            room.height - caption - 2 * outset,
            (room.width - 2 * outset) / aspect,
            viewport.height * LivenessCaptureStyle.windowHeightShare,
            LivenessCaptureStyle.maximumWindowHeight
        ))
        let width = height * aspect
        let group = height + 2 * outset + caption
        return CGRect(
            x: room.midX - width / 2,
            y: room.minY + (room.height - group) / 2 + outset,
            width: width,
            height: height
        )
    }

    /// The checked frame on screen that puts `normalizedOval` exactly on `window`, so the face in
    /// the window grows exactly as the visitor leans in toward the service's oval.
    static func previewRect(placing normalizedOval: CGRect, on window: CGRect) -> CGRect {
        guard normalizedOval.height > 0, window.height > 0 else { return .zero }
        let height = window.height / normalizedOval.height
        let width = height * previewAspectRatio
        return CGRect(
            x: window.minX - normalizedOval.minX * width,
            y: window.minY - normalizedOval.minY * height,
            width: width,
            height: height
        )
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
