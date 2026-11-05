import SwiftUI

/// The selected day's diamond: four boxes sitting on its vertices.
struct TodayVertexView: View {
    let exercises: [Exercise]
    let state: (Int) -> VertexState
    let onStart: (Exercise) -> Void
    let onReview: (Exercise) -> Void

    private let radius: CGFloat = 108

    // top, right, bottom, left — same vertex order as TetradGeometry
    private func offset(_ i: Int) -> CGSize {
        switch i {
        case 0: return CGSize(width: 0, height: -radius)
        case 1: return CGSize(width: radius, height: 0)
        case 2: return CGSize(width: 0, height: radius)
        default: return CGSize(width: -radius, height: 0)
        }
    }

    var body: some View {
        ZStack {
            Diamond()
                .stroke(EnkrateiaPalette.line, lineWidth: 1.5)
                .frame(width: radius * 2, height: radius * 2)

            // Fewer than four spreads evenly: a two-exercise day sits top and bottom.
            ForEach(Array(exercises.prefix(4).enumerated()), id: \.element.id) { i, exercise in
                VertexBox(exercise: exercise,
                          state: state(i),
                          onStart: { onStart(exercise) },
                          onReview: { onReview(exercise) })
                    .offset(offset(i * 4 / min(exercises.count, 4)))
            }
        }
        .frame(width: radius * 2 + 80, height: radius * 2 + 80)
    }
}

private struct VertexBox: View {
    let exercise: Exercise
    let state: VertexState
    let onStart: () -> Void
    let onReview: () -> Void

    private var tint: Color {
        switch state {
        case .locked: return EnkrateiaPalette.line
        case .active: return EnkrateiaPalette.gold
        case .done:   return EnkrateiaPalette.bronze
        }
    }

    var body: some View {
        Button(action: state == .done ? onReview : onStart) {
            VStack(spacing: 4) {
                Image(systemName: state == .done ? "checkmark" : exercise.stickFigureSymbol)
                    .font(.system(size: 20, weight: .light))
                Text(exercise.label.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(0.6)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .foregroundStyle(tint)
            .frame(width: 76, height: 62)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(state == .active ? EnkrateiaPalette.clay.opacity(0.18) : .clear)
            )
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(tint, lineWidth: state == .active ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .disabled(state == .locked)
        .animation(.easeInOut(duration: 0.2), value: state)
    }
}

private struct Diamond: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.midY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        EnkrateiaPalette.bg.ignoresSafeArea()
        TodayVertexView(exercises: defaultTetrad[0],
                        state: { [.done, .active, .locked, .locked][$0] },
                        onStart: { _ in },
                        onReview: { _ in })
    }
}
