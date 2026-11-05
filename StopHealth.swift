import HealthKit

/// How each stop is recorded in Apple Health. Used to start workouts on the watch
/// and to find them again on the phone.
extension WeekStop {
    var healthActivity: HKWorkoutActivityType {
        switch id {
        case "swim": return .swimming
        case "kayak": return .paddleSports
        case "hike": return .hiking
        case "homelift": return .functionalStrengthTraining
        default: return .traditionalStrengthTraining
        }
    }

    var workoutConfiguration: HKWorkoutConfiguration {
        let config = HKWorkoutConfiguration()
        config.activityType = healthActivity
        config.locationType = (id == "kayak" || id == "hike") ? .outdoor : .indoor
        if id == "swim" {
            config.swimmingLocationType = .pool
            config.lapLength = HKQuantity(unit: .yard(), doubleValue: 25)
        }
        return config
    }
}
