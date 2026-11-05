import Foundation
import HealthKit
import Observation

/// Runs the HealthKit session: keeps the app up during a stop and saves it toward the rings.
@MainActor @Observable final class WorkoutManager {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    private(set) var activeStopID: String?
    private(set) var startDate: Date?
    private(set) var isBusy = false
    var errorMessage: String?

    static func configuration(for stop: WeekStop) -> HKWorkoutConfiguration {
        let config = HKWorkoutConfiguration()
        switch stop.id {
        case "swim":
            config.activityType = .swimming
            config.locationType = .indoor
            config.swimmingLocationType = .pool
            config.lapLength = HKQuantity(unit: .yard(), doubleValue: 25)
        case "kayak":
            config.activityType = .paddleSports
            config.locationType = .outdoor
        case "hike":
            config.activityType = .hiking
            config.locationType = .outdoor
        default:
            config.activityType = .traditionalStrengthTraining
            config.locationType = .indoor
        }
        return config
    }

    func start(_ stop: WeekStop) async {
        guard activeStopID == nil, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        errorMessage = nil
        do {
            let energy = HKQuantityType(.activeEnergyBurned)
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), energy],
                                                 read: [energy, HKQuantityType(.heartRate)])

            let config = Self.configuration(for: stop)
            let session = try HKWorkoutSession(healthStore: store, configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: config)

            let now = Date.now
            session.startActivity(with: now)
            try await builder.beginCollection(at: now)

            self.session = session
            self.builder = builder
            activeStopID = stop.id
            startDate = now
        } catch {
            errorMessage = "Couldn't start the workout."
        }
    }

    func end() async {
        guard let session, let builder, !isBusy else { return }
        isBusy = true
        defer { isBusy = false }
        session.end()
        do {
            try await builder.endCollection(at: .now)
            _ = try await builder.finishWorkout()
        } catch {
            errorMessage = "Couldn't save the workout."
        }
        self.session = nil
        self.builder = nil
        activeStopID = nil
        startDate = nil
    }
}
