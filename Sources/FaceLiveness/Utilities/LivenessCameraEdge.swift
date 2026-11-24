import Foundation
import UIKit

/// The edge of the screen the front camera sits beyond, so the guidance can point at the lens.
///
/// iOS has no API for where the camera is, so this comes from the model: since the 10th-generation
/// iPad (2022) every new iPad has its front camera in the middle of the long edge, which is the
/// right-hand edge when the iPad is held in portrait. Earlier iPads, and the iPad mini until its
/// 2026 model, have it in the middle of the top short edge in portrait.
enum LivenessCameraEdge: Equatable {
    case top
    case bottom
    case left
    case right

    /// Model identifiers of iPads with the camera on the long edge. Families from `iPad17` on
    /// are all long-edge, so they are matched by number rather than listed.
    private static let longEdgeModels: Set<String> = [
        "iPad13,18", "iPad13,19", // iPad (10th generation)
        "iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11", // iPad Air 11- and 13-inch (M2)
        "iPad15,3", "iPad15,4", "iPad15,5", "iPad15,6", // iPad Air 11- and 13-inch (M3)
        "iPad15,7", "iPad15,8", // iPad (A16)
        "iPad16,3", "iPad16,4", "iPad16,5", "iPad16,6" // iPad Pro 11- and 13-inch (M4)
    ]

    /// The edge for this iPad held in `orientation`.
    static func current(in orientation: UIInterfaceOrientation) -> LivenessCameraEdge {
        edge(forModel: modelIdentifier, in: orientation)
    }

    static func edge(forModel model: String, in orientation: UIInterfaceOrientation) -> LivenessCameraEdge {
        if hasLongEdgeCamera(model) {
            // In portrait the camera is on the right; landscape-right turns that edge to the top.
            switch orientation {
            case .portraitUpsideDown: return .left
            case .landscapeLeft: return .bottom
            case .landscapeRight: return .top
            default: return .right
            }
        }
        // In portrait the camera is at the top; landscape-right turns that edge to the left.
        switch orientation {
        case .portraitUpsideDown: return .bottom
        case .landscapeLeft: return .right
        case .landscapeRight: return .left
        default: return .top
        }
    }

    static func hasLongEdgeCamera(_ model: String) -> Bool {
        if longEdgeModels.contains(model) { return true }
        guard model.hasPrefix("iPad"),
              let family = Int(model.dropFirst(4).prefix { $0 != "," })
        else { return false }
        return family >= 17
    }

    /// The hardware model, such as "iPad16,3"; the simulated one in the simulator.
    static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        var system = utsname()
        uname(&system)
        return withUnsafeBytes(of: &system.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
