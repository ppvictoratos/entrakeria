import SwiftUI

struct TetradRibbonView: View {
    let days: Int
    let todayNumber: Int
    let progress: Int
    @Binding var selectedDay: Int

    private let unit: CGFloat = 60
    private let height: CGFloat = 160

    private var width: CGFloat { unit * CGFloat(days) * 2 }

    /// Today's tracer sits on the vertex of the next exercise; four done moves it to the next day's top.
    private var tracerSegment: Int { min((todayNumber - 1) * 4 + progress, days * 4 - 1) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    Canvas { ctx, size in
                        let centerY = size.height / 2
                        ctx.stroke(TetradGeometry.ribbonPath(days: days, unit: unit, centerY: centerY),
                                   with: .color(EnkrateiaPalette.line), lineWidth: 1.5)

                        let v = TetradGeometry.vertices(forDay: selectedDay - 1, unit: unit, centerY: centerY)
                        var selected = Path()
                        selected.move(to: v[0])
                        for p in v.dropFirst() { selected.addLine(to: p) }
                        selected.closeSubpath()
                        ctx.stroke(selected, with: .color(EnkrateiaPalette.gold.opacity(0.6)), lineWidth: 1.5)

                        let seg = tracerSegment
                        let p = TetradGeometry.vertex(day: seg / 4, corner: seg % 4, unit: unit, centerY: centerY)
                        ctx.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)),
                                 with: .radialGradient(Gradient(colors: [EnkrateiaPalette.gold, .clear]),
                                                       center: p, startRadius: 0, endRadius: 12))
                    }

                    HStack(spacing: 0) {
                        ForEach(1...days, id: \.self) { day in
                            Color.clear
                                .frame(width: unit * 2, height: height)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedDay = day }
                                .id(day)
                        }
                    }
                }
                .frame(width: width, height: height)
            }
            .onAppear { proxy.scrollTo(todayNumber, anchor: .center) }
            .onChange(of: todayNumber) { _, new in
                withAnimation { proxy.scrollTo(new, anchor: .center) }
            }
        }
    }
}
