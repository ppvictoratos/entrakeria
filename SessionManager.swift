import Foundation
import Observation
import SwiftData

enum VertexState { case locked, active, done }

@Observable final class SessionManager {
    var activeCycle: TetradCycle?
    var activeSession: WorkoutSession?
    var activeDayIndex: Int = 0
    var activeExercise: Exercise?
    var elapsed: TimeInterval = 0     // stopwatch, counts up
    var laps: [TimeInterval] = []     // one lap per rep
    var isRunning = false

    let tetrad: [[Exercise]] = defaultTetrad

    // MARK: - Pure functions

    /// Exercises for ribbon day 1...30 — the tetrad repeats every four days.
    func exercises(forDay day: Int) -> [Exercise] { tetrad[(day - 1) % 4] }

    /// Today's progress in diamond corners; a two-exercise day steps two corners per exercise.
    var activeCorner: Int {
        let day = tetrad[activeDayIndex]
        let logged = Set((activeSession?.logs ?? []).map(\.exerciseName))
        return day.filter { logged.contains($0.name) }.count * 4 / day.count
    }

    /// Done when logged; only today unlocks in sequence (first unlogged is active).
    func state(at index: Int, day: Int, cycles: [TetradCycle], today: Int) -> VertexState {
        let exercises = exercises(forDay: day)
        let logged = Set((Self.session(forDay: day, in: cycles)?.logs ?? []).map(\.exerciseName))
        if logged.contains(exercises[index].name) { return .done }
        guard day == today else { return .locked }
        let firstOpen = exercises.firstIndex { !logged.contains($0.name) }
        return index == firstOpen ? .active : .locked
    }

    /// One stopwatch tick. Pure: elapsed + delta.
    static func tick(_ elapsed: TimeInterval, by delta: TimeInterval) -> TimeInterval {
        elapsed + delta
    }

    func tick(by delta: TimeInterval) {
        guard isRunning else { return }
        elapsed = Self.tick(elapsed, by: delta)
    }

    static let ribbonDays = 30

    /// Day 1...30 maps onto stored cycles four days at a time, in start-date order.
    static func session(forDay day: Int, in cycles: [TetradCycle]) -> WorkoutSession? {
        let ordinal = (day - 1) / 4
        guard cycles.indices.contains(ordinal) else { return nil }
        return cycles[ordinal].sessions.first { $0.dayIndex == (day - 1) % 4 }
    }

    func dayNumber(in cycles: [TetradCycle]) -> Int {
        let ordinal = cycles.firstIndex { $0 === activeCycle } ?? 0
        return ordinal * 4 + activeDayIndex + 1
    }

    // MARK: - SwiftData

    /// Resolves cycle, day, and session from what is stored — the day index is derived,
    /// never remembered, so a relaunch resumes exactly where the tetrad left off.
    func bootstrap(in context: ModelContext) {
        let cycle = activeCycle ?? latestCycle(in: context)

        guard let resume = firstIncompleteDay(in: cycle) else {
            // Tetrad finished: open the next cycle and resolve against that instead.
            let next = TetradCycle()
            context.insert(next)
            activeCycle = next
            activeSession = nil
            return bootstrap(in: context)
        }

        activeCycle = cycle
        activeDayIndex = resume
        if let existing = cycle.sessions.first(where: { $0.dayIndex == resume }) {
            activeSession = existing
        } else {
            let s = WorkoutSession(dayIndex: resume)
            context.insert(s)
            cycle.sessions.append(s)
            activeSession = s
        }
    }

    private func latestCycle(in context: ModelContext) -> TetradCycle {
        let stored = (try? context.fetch(FetchDescriptor<TetradCycle>())) ?? []
        if let last = stored.sorted(by: { $0.startDate < $1.startDate }).last { return last }
        let fresh = TetradCycle()
        context.insert(fresh)
        return fresh
    }

    /// First day 0...3 that still has unlogged exercises, or nil when the tetrad is done.
    /// Matched by name, so logs from a retired program never count toward the new one.
    private func firstIncompleteDay(in cycle: TetradCycle) -> Int? {
        (0...3).first { day in
            let logs = cycle.sessions.first { $0.dayIndex == day }?.logs ?? []
            return !Set(tetrad[day].map(\.name)).isSubset(of: logs.map(\.exerciseName))
        }
    }

    func select(_ exercise: Exercise) {
        activeExercise = exercise
        elapsed = 0
        laps = []
        isRunning = false
    }

    func start() { isRunning = true }

    /// Marks one set at the current split. Stops on its own at the target count.
    func lap() {
        guard isRunning, laps.count < (activeExercise?.target ?? 0) else { return }
        laps.append(elapsed)
        if laps.count == activeExercise?.target { isRunning = false }
    }

    /// Logs the exercise, then re-derives the day — which rolls the tetrad over when day 4 closes.
    func completeExercise(_ exercise: Exercise, in context: ModelContext) {
        bootstrap(in: context)
        guard let session = activeSession else { return }

        // Log what was actually done, not what was prescribed.
        let done = laps.count
        let log = ExerciseLog(exerciseName: exercise.name,
                              reps: done,
                              duration: elapsed)
        log.completedAt = .now
        context.insert(log)
        session.logs.append(log)
        session.totalDuration += elapsed

        activeExercise = nil
        elapsed = 0
        laps = []
        isRunning = false

        // Autosave alone can lose a rep if the app dies right after; a set is worth a flush.
        try? context.save()

        bootstrap(in: context)
    }
}
