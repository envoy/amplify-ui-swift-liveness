import CoreGraphics
import Foundation
import SwiftUI
import UIKit

/// A CSS `cubic-bezier()` timing curve, so the guidance moves exactly as the approved design does.
struct LivenessTimingCurve: Equatable {
    static let easeInOut = LivenessTimingCurve(0.42, 0, 0.58, 1)
    /// The design's glide: a quick start that settles slowly.
    static let glide = LivenessTimingCurve(0.45, 0, 0.2, 1)

    let x1: Double
    let y1: Double
    let x2: Double
    let y2: Double

    init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
        self.x1 = x1
        self.y1 = y1
        self.x2 = x2
        self.y2 = y2
    }

    /// The eased progress at `x` (0...1), solving the curve for x then reading its y.
    func value(at x: Double) -> Double {
        guard x > 0 else { return 0 }
        guard x < 1 else { return 1 }
        var low = 0.0
        var high = 1.0
        var t = x
        for _ in 0..<24 {
            let current = Self.component(t, x1, x2)
            if abs(current - x) < 1e-6 { break }
            if current < x { low = t } else { high = t }
            t = (low + high) / 2
        }
        return Self.component(t, y1, y2)
    }

    private static func component(_ t: Double, _ p1: Double, _ p2: Double) -> Double {
        let inverse = 1 - t
        return 3 * inverse * inverse * t * p1 + 3 * inverse * t * t * p2 + t * t * t
    }
}

/// CSS-style keyframes: values at offsets through a loop, eased per segment by one curve.
struct LivenessKeyframes {
    let stops: [(offset: Double, value: Double)]
    let curve: LivenessTimingCurve

    init(_ stops: [(Double, Double)], curve: LivenessTimingCurve) {
        self.stops = stops.map { (offset: $0.0, value: $0.1) }
        self.curve = curve
    }

    /// The value at `progress` (0...1) through the loop.
    func value(at progress: Double) -> Double {
        guard let first = stops.first, let last = stops.last else { return 0 }
        guard progress > first.offset else { return first.value }
        guard progress < last.offset else { return last.value }
        for (start, end) in zip(stops, stops.dropFirst()) where progress <= end.offset {
            let span = end.offset - start.offset
            guard span > 0 else { return end.value }
            let eased = curve.value(at: (progress - start.offset) / span)
            return start.value + (end.value - start.value) * eased
        }
        return last.value
    }

    /// The value `seconds` into a loop `period` long, started `delay` seconds late.
    func value(atSeconds seconds: TimeInterval, period: TimeInterval, delay: TimeInterval = 0) -> Double {
        let phase = (seconds - delay).truncatingRemainder(dividingBy: period)
        return value(at: (phase < 0 ? phase + period : phase) / period)
    }
}

/// Redraws its content every frame with the seconds since `start`; with Reduce Motion, once.
struct LivenessClock<Content: View>: View {
    let start: Date
    let content: (TimeInterval) -> Content

    init(since start: Date, @ViewBuilder content: @escaping (TimeInterval) -> Content) {
        self.start = start
        self.content = content
    }

    var body: some View {
        if UIAccessibility.isReduceMotionEnabled {
            content(0)
        } else {
            TimelineView(.animation) { context in
                content(context.date.timeIntervalSince(start))
            }
        }
    }
}
