import SwiftUI

/// An SF Symbol, except for the kayak, which Apple doesn't draw.
struct StopIcon: View {
    let symbol: String
    let size: CGFloat
    var weight: Font.Weight = .light

    var body: some View {
        if symbol == KayakShape.symbolName {
            KayakShape()
                .fill(.foreground, style: FillStyle(eoFill: true))
                .frame(width: size * 1.5, height: size * 1.5)
        } else {
            Image(systemName: symbol)
                .font(.system(size: size, weight: weight))
        }
    }
}

/// A kayak from above, tilted, with a double-bladed paddle across the cockpit.
struct KayakShape: Shape {
    static let symbolName = "entrakeria.kayak"

    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }

        var hull = Path()
        hull.move(to: pt(0, 0.5))
        hull.addQuadCurve(to: pt(1, 0.5), control: pt(0.5, 0.22))
        hull.addQuadCurve(to: pt(0, 0.5), control: pt(0.5, 0.78))
        hull.closeSubpath()
        hull.addEllipse(in: CGRect(x: 0.38 * w, y: 0.44 * h, width: 0.24 * w, height: 0.12 * h))

        var paddle = Path()
        paddle.addRect(CGRect(x: 0.485 * w, y: 0.06 * h, width: 0.03 * w, height: 0.88 * h))
        paddle.addEllipse(in: CGRect(x: 0.44 * w, y: 0, width: 0.12 * w, height: 0.2 * h))
        paddle.addEllipse(in: CGRect(x: 0.44 * w, y: 0.8 * h, width: 0.12 * w, height: 0.2 * h))
        let spin = CGAffineTransform(translationX: 0.5 * w, y: 0.5 * h)
            .rotated(by: .pi / 3.5)
            .translatedBy(x: -0.5 * w, y: -0.5 * h)

        // Hull minus the paddle's path keeps a thin outline where they cross.
        var out = hull.applying(CGAffineTransform(translationX: 0.5 * w, y: 0.5 * h)
            .rotated(by: -.pi / 9)
            .translatedBy(x: -0.5 * w, y: -0.5 * h))
        out.addPath(paddle.applying(spin))
        return out
    }
}
