import SwiftData
import SwiftUI

struct TetradView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TetradCycle.startDate) private var cycles: [TetradCycle]
    @State private var session = SessionManager()
    @State private var selectedDay = 1
    @State private var reviewing: LoggedExercise?
    @State private var showingAdditional = false

    private var today: Int { session.dayNumber(in: cycles) }

    var body: some View {
        ZStack {
            EnkrateiaPalette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                MeanderBand()
                    .frame(height: 18)
                    .padding(.top, 8)

                Text("ΕΝΤΡΑΚΕΡΙΑ")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .kerning(6)
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .padding(.top, 10)

                TetradRibbonView(days: SessionManager.ribbonDays,
                                 todayNumber: today,
                                 progress: session.activeCorner,
                                 selectedDay: $selectedDay)
                    .padding(.top, 8)

                Text("DAY \(selectedDay) OF \(SessionManager.ribbonDays)")
                    .font(.system(size: 11, weight: .medium))
                    .kerning(2)
                    .foregroundStyle(selectedDay == today ? EnkrateiaPalette.gold : EnkrateiaPalette.line)

                Spacer(minLength: 0)

                TodayVertexView(exercises: session.exercises(forDay: selectedDay),
                                state: { session.state(at: $0, day: selectedDay, cycles: cycles, today: today) },
                                onStart: session.select,
                                onReview: review)

                Spacer(minLength: 0)

                Button { showingAdditional = true } label: {
                    Text("ADDITIONAL WORKOUTS")
                        .font(.system(size: 10, weight: .medium))
                        .kerning(2)
                        .foregroundStyle(EnkrateiaPalette.bronze)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                MeanderBand()
                    .frame(height: 18)
                    .padding(.bottom, 8)
            }
        }
        .onAppear { session.bootstrap(in: context) }
        .onChange(of: today) { _, new in selectedDay = new }
        .sheet(item: $session.activeExercise) { exercise in
            ExerciseModal(exercise: exercise, session: session) {
                session.completeExercise(exercise, in: context)
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingAdditional) {
            AdditionalWorkoutsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $reviewing) { item in
            ExerciseHistoryView(exercise: item.exercise, log: item.log)
                .presentationDetents([.large])
        }
    }

    private func review(_ exercise: Exercise) {
        guard let log = SessionManager.session(forDay: selectedDay, in: cycles)?
            .logs.first(where: { $0.exerciseName == exercise.name }) else { return }
        reviewing = LoggedExercise(exercise: exercise, log: log)
    }
}

#Preview {
    TetradView()
        .modelContainer(for: [TetradCycle.self, WorkoutSession.self, ExerciseLog.self],
                        inMemory: true)
}
