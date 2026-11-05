import CoreGraphics
import SwiftUI

/// The tetrad shape equation. Pure math, no UI coupling — keep it that way.
enum TetradGeometry {
    /// Returns the 4 vertices of day `index`'s diamond (top, right, bottom, left),
    /// offset horizontally so consecutive days chain left→right.
    static func vertices(forDay index: Int, unit: CGFloat, centerY: CGFloat) -> [CGPoint] {
        let cx = unit * (CGFloat(index) * 2.0 + 1.0)   // horizontal center per day
        let half = unit * 0.7
        return [
            CGPoint(x: cx, y: centerY - half),   // top
            CGPoint(x: cx + half, y: centerY),   // right
            CGPoint(x: cx, y: centerY + half),   // bottom
            CGPoint(x: cx - half, y: centerY)    // left
        ]
    }

    static func vertex(day: Int, corner: Int, unit: CGFloat, centerY: CGFloat) -> CGPoint {
        vertices(forDay: day, unit: unit, centerY: centerY)[corner]
    }

    /// Full path across N days: each day's 4 vertices, connected in a continuous ribbon.
    static func ribbonPath(days: Int, unit: CGFloat, centerY: CGFloat) -> Path {
        var path = Path()
        for d in 0..<days {
            let v = vertices(forDay: d, unit: unit, centerY: centerY)
            if d == 0 { path.move(to: v[0]) }
            for p in v { path.addLine(to: p) }
            path.addLine(to: v[0]) // close the diamond
        }
        return path
    }

    /// Point along the ribbon at scrub progress t (0...1) — used for the gradient tracer.
    static func point(atProgress t: CGFloat, days: Int, unit: CGFloat, centerY: CGFloat) -> CGPoint {
        let totalSegments = days * 4 // four sides per day; the close IS the fourth side
        let segF = t * CGFloat(totalSegments)
        let day = min(days - 1, Int(segF) / 4)
        let v = vertices(forDay: day, unit: unit, centerY: centerY)
        let ring = v + [v[0]]           // wrap so the last side runs left → top
        let localT = segF - CGFloat(Int(segF))
        let segIdx = Int(segF) % 4
        let a = ring[segIdx], b = ring[segIdx + 1]
        return CGPoint(x: a.x + (b.x - a.x) * localT, y: a.y + (b.y - a.y) * localT)
    }
}
