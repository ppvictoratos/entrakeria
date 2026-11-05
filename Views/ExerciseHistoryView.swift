import SwiftUI

struct LoggedExercise: Identifiable {
    let exercise: Exercise
    let log: ExerciseLog
    var id: UUID { exercise.id }
}

struct ExerciseHistoryView: View {
    let exercise: Exercise
    let log: ExerciseLog

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

                Text("\(log.reps) / \(exercise.target) \(exercise.countUnit)S")
                    .font(.system(size: 13, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(EnkrateiaPalette.gold)

                Text(clock(log.duration))
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .foregroundStyle(EnkrateiaPalette.bronze)

                if let completedAt = log.completedAt {
                    Text("LOGGED \(completedAt.formatted(date: .abbreviated, time: .shortened).uppercased())")
                        .font(.system(size: 10, weight: .medium))
                        .kerning(1.5)
                        .foregroundStyle(EnkrateiaPalette.line)
                }
            }
            .padding(32)
        }
    }

    private func clock(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}
