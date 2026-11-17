import HealthKit

/// How each stop is recorded in Apple Health. Used to start workouts on the watch
/// and to find them again on the phone.
extension WeekStop {
    var healthActivity: HKWorkoutActivityType {
        switch id {
        case "swim": return .swimming
        case "nature": return .hiking
        case "morning": return .coreTraining
        default: return .traditionalStrengthTraining
        }
    }

    /// Everything that counts as this stop when reading Health back on the phone.
    var healthActivities: [HKWorkoutActivityType] {
        switch id {
        case "nature": return [.hiking, .paddleSports, .walking]
        case "machines": return [.traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining]
        default: return [healthActivity]
        }
    }

    var workoutConfiguration: HKWorkoutConfiguration {
        let config = HKWorkoutConfiguration()
        config.activityType = healthActivity
        config.locationType = isOutdoors ? .outdoor : .indoor
        if id == "swim" {
            config.swimmingLocationType = .pool
            config.lapLength = HKQuantity(unit: .yard(), doubleValue: 25)
        }
        return config
    }
}
