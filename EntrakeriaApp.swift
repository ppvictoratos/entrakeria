import SwiftData
import SwiftUI

@main
struct EntrakeriaApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var container = SharedStore.container()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(container)
        // The widget writes to the same store from its own process. A fresh container on
        // return to the foreground is the simplest way to pick those sets up.
        .onChange(of: scenePhase) { old, phase in
            guard phase == .active else { return }
            if old == .background { container = SharedStore.container() }
            WatchSync.shared.container = container
            WatchSync.shared.push()
        }
        .onChange(of: container, initial: true) { _, fresh in
            WatchSync.shared.container = fresh
            WatchSync.shared.activate()
        }
    }
}
