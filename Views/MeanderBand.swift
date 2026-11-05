import SwiftUI

/// Running Greek key: one unbroken line that spirals in and back out of each unit.
struct MeanderBand: View {
    // On a 6-wide, 5-tall grid. Each unit ends where the next one starts.
    private static let unit: [(CGFloat, CGFloat)] = [
        (0, 5), (0, 0), (5, 0), (5, 4), (2, 4), (2, 2), (4, 2), (4, 1), (1, 1), (1, 5), (6, 5)
    ]

    private let strokeRatio: CGFloat = 0.45

    var body: some View {
        Canvas { ctx, size in
            // Leave room for the stroke so the outer edges don't clip.
            let step = size.height / (5 + strokeRatio)
            ctx.translateBy(x: 0, y: step * strokeRatio / 2)
            let period = step * 6
            let count = max(1, Int((size.width - step) / period))
            let originX = (size.width - CGFloat(count) * period - step) / 2

            var path = Path()
            path.move(to: CGPoint(x: originX, y: step * 5))
            for i in 0..<count {
                let ox = originX + CGFloat(i) * period
                for (x, y) in Self.unit {
                    path.addLine(to: CGPoint(x: ox + x * step, y: y * step))
                }
            }
            path.addLine(to: CGPoint(x: originX + CGFloat(count) * period, y: 0))

            ctx.stroke(path, with: .color(EnkrateiaPalette.clay),
                       style: StrokeStyle(lineWidth: step * strokeRatio, lineCap: .square, lineJoin: .miter))
        }
    }
}

#Preview {
    MeanderBand().frame(height: 18).padding()
}
