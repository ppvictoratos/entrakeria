import Foundation
import HealthKit

/// Pulls a stop's stats out of workouts already recorded in Apple Health.
enum HealthImporter {
    private static let store = HKHealthStore()

    /// One line per matching workout that day, or nil when there are none.
    static func summary(for stop: WeekStop, on day: Date) async throws -> String? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }

        let energy = HKQuantityType(.activeEnergyBurned)
        let swim = HKQuantityType(.distanceSwimming)
        let walk = HKQuantityType(.distanceWalkingRunning)
        try await store.requestAuthorization(toShare: [],
                                             read: [HKObjectType.workoutType(), energy, swim, walk])

        let start = Week.calendar.startOfDay(for: day)
        guard let end = Week.calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            HKQuery.predicateForSamples(withStart: start, end: end),
            HKQuery.predicateForWorkouts(with: stop.healthActivity)
        ])
        let query = HKSampleQueryDescriptor(predicates: [.workout(predicate)],
                                            sortDescriptors: [SortDescriptor(\.startDate)])
        let workouts = try await query.result(for: store)
        guard !workouts.isEmpty else { return nil }

        return workouts.map { workout in
            var parts = ["\(Int((workout.duration / 60).rounded())) min"]
            if let yards = workout.statistics(for: swim)?.sumQuantity()?.doubleValue(for: .yard()), yards > 0 {
                parts.append("\(Int(yards.rounded()).formatted()) yd")
            }
            if let miles = workout.statistics(for: walk)?.sumQuantity()?.doubleValue(for: .mile()), miles > 0 {
                parts.append(String(format: "%.1f mi", miles))
            }
            if let kcal = workout.statistics(for: energy)?.sumQuantity()?.doubleValue(for: .kilocalorie()), kcal > 0 {
                parts.append("\(Int(kcal.rounded())) kcal")
            }
            return parts.joined(separator: " · ")
        }.joined(separator: "\n")
    }
}
