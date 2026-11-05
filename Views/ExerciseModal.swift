import SwiftUI

struct ExerciseModal: View {
    let exercise: Exercise
    let session: SessionManager
    let onDone: () -> Void

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var setsDone: Int { session.laps.count }
    private var finished: Bool { setsDone >= exercise.target }

    var body: some View {
        ZStack {
            EnkrateiaPalette.bg.ignoresSafeArea()

            VStack(spacing: 24) {
                Text(exercise.name.uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .kerning(2)
                    .foregroundStyle(EnkrateiaPalette.gold)
                    .multilineTextAlignment(.center)

                Text(exercise.detail.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .kerning(1)
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .multilineTextAlignment(.center)

                Image(systemName: exercise.stickFigureSymbol)
                    .font(.system(size: 84, weight: .ultraLight))
                    .foregroundStyle(EnkrateiaPalette.clay)
                    .frame(height: 120)

                Text("\(setsDone) / \(exercise.target) \(exercise.countUnit)S")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(finished ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)
                    .contentTransition(.numericText())

                Text(clock(session.elapsed))
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .foregroundStyle(session.isRunning ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)

                // Last few set splits, newest first — enough to check pace without scrolling.
                if !session.laps.isEmpty {
                    VStack(spacing: 2) {
                        ForEach(Array(session.laps.enumerated().reversed().prefix(3)), id: \.offset) { i, at in
                            Text("\(exercise.countUnit) \(i + 1)   \(clock(at))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(EnkrateiaPalette.line)
                        }
                    }
                    .frame(height: 44, alignment: .top)
                } else {
                    Color.clear.frame(height: 44)
                }

                primaryButton
                doneButton
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 32)
        }
        .onReceive(ticker) { _ in
            withAnimation { session.tick(by: 1) }
        }
    }

    @ViewBuilder private var primaryButton: some View {
        Button {
            withAnimation { session.isRunning ? session.lap() : session.start() }
        } label: {
            Text(session.isRunning ? exercise.countUnit : (finished ? "DONE — \(clock(session.elapsed))" : "START"))
                .font(.system(size: 15, weight: .bold))
                .kerning(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(session.isRunning ? EnkrateiaPalette.gold : EnkrateiaPalette.clay)
                .foregroundStyle(EnkrateiaPalette.bg)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(finished)
        .opacity(finished ? 0.4 : 1)
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("LOG SET")
                .font(.system(size: 13, weight: .bold))
                .kerning(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(EnkrateiaPalette.clay)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.clay, lineWidth: 1))
        }
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
