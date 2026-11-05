import SwiftData
import SwiftUI

@main
struct EntrakeriaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [TetradCycle.self, WorkoutSession.self, ExerciseLog.self,
                         StopLog.self, BackCheck.self])
    }
}
