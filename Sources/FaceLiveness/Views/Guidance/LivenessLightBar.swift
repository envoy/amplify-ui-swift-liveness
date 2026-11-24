import SwiftUI
import UIKit

/// The light bar: a bright frame round the camera image that lights the visitor's face like a
/// ring light. Where the camera is, the bar swells into a tab holding a chevron that drifts toward
/// the lens, so the light and the cue to look there are one shape.
struct LivenessLightBar: View {
    let edge: LivenessCameraEdge
    /// How wide the bar is; it widens to give more light when the face is too dark.
    let width: CGFloat
    let start: Date

    var body: some View {
        GeometryReader { proxy in
            let geometry = LivenessLightBarGeometry(size: proxy.size, edge: edge, width: width)
            ZStack(alignment: .topLeading) {
                // The light falling onto the edges of the image.
                geometry.window
                    .stroke(Color.white.opacity(0.26), lineWidth: 32)
                    .blur(radius: 18)
                    .mask(geometry.window.fill(Color.white))

                geometry.frame
                    .fill(Color.white, style: FillStyle(eoFill: true))

                LivenessClock(since: start) { seconds in
                    geometry.chevron(drift: LivenessLightBarGeometry.drift.value(atSeconds: seconds, period: 1.8))
                        .stroke(
                            LivenessCaptureStyle.chevronInk,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                        )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: width)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The light bar's shapes, drawn for a camera on the top edge and mapped onto the real edge.
struct LivenessLightBarGeometry {
    /// The chevron drifts 7 pt toward the lens and back, easing both ways.
    static let drift = LivenessKeyframes([(0, 0), (0.5, 7), (1, 0)], curve: .easeInOut)
    /// The camera window's corner radius.
    static let windowCornerRadius: CGFloat = 30
    /// Handle length for a cubic quarter circle.
    private static let quarterCircle: CGFloat = 0.5523

    let size: CGSize
    let edge: LivenessCameraEdge
    let width: CGFloat

    /// The length of the camera's edge and the distance across from it.
    private var along: CGFloat { edge == .top || edge == .bottom ? size.width : size.height }
    private var across: CGFloat { edge == .top || edge == .bottom ? size.height : size.width }

    /// The tab's half width, how far it reaches past the bar, and its shoulder length.
    private let tab: (halfWidth: CGFloat, depth: CGFloat, shoulder: CGFloat) = (70, 26, 26)

    /// The chevron's tip, measured from the camera's edge.
    private var tipDepth: CGFloat { (width + tab.depth) / 2 - 5 }

    /// Maps a point drawn for a top-edge camera onto the real edge.
    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        switch edge {
        case .top: CGPoint(x: x, y: y)
        case .bottom: CGPoint(x: x, y: size.height - y)
        case .left: CGPoint(x: y, y: x)
        case .right: CGPoint(x: size.width - y, y: x)
        }
    }

    /// The camera window: the screen inside the bar, with the tab cut into its camera edge.
    var window: Path {
        let t = width
        let r = Self.windowCornerRadius
        let k = r * Self.quarterCircle
        let a = along
        let b = across
        let c = a / 2
        let (hw, d, s) = tab
        var path = Path()
        path.move(to: point(t + r, t))
        path.addLine(to: point(c - hw - s, t))
        path.addCurve(to: point(c - hw + s, t + d), control1: point(c - hw, t), control2: point(c - hw, t + d))
        path.addLine(to: point(c + hw - s, t + d))
        path.addCurve(to: point(c + hw + s, t), control1: point(c + hw, t + d), control2: point(c + hw, t))
        path.addLine(to: point(a - t - r, t))
        path.addCurve(to: point(a - t, t + r), control1: point(a - t - r + k, t), control2: point(a - t, t + r - k))
        path.addLine(to: point(a - t, b - t - r))
        path.addCurve(to: point(a - t - r, b - t), control1: point(a - t, b - t - r + k), control2: point(a - t - r + k, b - t))
        path.addLine(to: point(t + r, b - t))
        path.addCurve(to: point(t, b - t - r), control1: point(t + r - k, b - t), control2: point(t, b - t - r + k))
        path.addLine(to: point(t, t + r))
        path.addCurve(to: point(t + r, t), control1: point(t, t + r - k), control2: point(t + r - k, t))
        path.closeSubpath()
        return path
    }

    /// The bar itself: the whole screen less the window.
    var frame: Path {
        var path = Path(CGRect(origin: .zero, size: size))
        path.addPath(window)
        return path
    }

    /// The chevron in the tab, pointing out of the screen at the lens, `drift` points toward it.
    func chevron(drift: CGFloat) -> Path {
        let c = along / 2
        let tip = tipDepth - drift
        var path = Path()
        path.move(to: point(c - 14, tip + 7))
        path.addLine(to: point(c, tip - 7))
        path.addLine(to: point(c + 14, tip + 7))
        return path
    }
}
