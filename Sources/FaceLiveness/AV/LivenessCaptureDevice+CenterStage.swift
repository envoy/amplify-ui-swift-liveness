import AVFoundation
import Foundation

extension LivenessCaptureDevice {
    /// Turns Center Stage off for the check, so the camera never reframes or zooms on the face:
    /// the face's size in the frame must change only when the visitor moves. Call while the
    /// device is locked.
    static func turnOffCenterStage() {
        if #available(iOS 14.5, *), AVCaptureDevice.isCenterStageEnabled {
            AVCaptureDevice.centerStageControlMode = .app
            AVCaptureDevice.isCenterStageEnabled = false
        }
    }
}
