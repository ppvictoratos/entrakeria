import SwiftUI

@main
struct EntrakeriaWatchApp: App {
    @State private var workout = WorkoutManager()
    @State private var phone = PhoneMirror()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchHomeView()
            }
            .environment(workout)
            .environment(phone)
            .onAppear { phone.activate() }
        }
    }
}
