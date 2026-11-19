import SwiftUI

struct OvalProgress: Shape {
    private static let segments = 96
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let sweep = min(max(progress, 0), 1) * .pi
        var path = Path()
        guard sweep > 0 else { return path }
        path.addLines(points(in: rect, from: .pi / 2, to: .pi / 2 - sweep))
        path.addLines(points(in: rect, from: .pi / 2, to: .pi / 2 + sweep))
        return path
    }

    private func points(in rect: CGRect, from start: Double, to end: Double) -> [CGPoint] {
        (0...Self.segments).map { step in
            let angle = start + (end - start) * Double(step) / Double(Self.segments)
            return CGPoint(
                x: rect.midX + rect.width / 2 * cos(angle),
                y: rect.midY + rect.height / 2 * sin(angle)
            )
        }
    }
}
