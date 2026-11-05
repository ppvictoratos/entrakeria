import SwiftData
import SwiftUI

@main
struct EntrakeriaWatchApp: App {
    @State private var workout = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
            .environment(workout)
        }
        .modelContainer(for: [StopLog.self])
    }
}
