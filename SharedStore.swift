import Foundation
import SwiftData

/// One SwiftData store in the app group, so the widget and the app read the same week.
enum SharedStore {
    static let groupID = "group.com.portokali.Entrakeria"
    static let widgetKind = "EntrakeriaToday"

    static let models: [any PersistentModel.Type] = [
        TetradCycle.self, WorkoutSession.self, ExerciseLog.self,
        StopLog.self, BackCheck.self, MoveConfig.self
    ]

    static var url: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
            ?? URL.applicationSupportDirectory
        return base.appendingPathComponent("Entrakeria.store")
    }

    static func container() -> ModelContainer {
        adoptDefaultStoreIfNeeded()
        let config = ModelConfiguration(url: url)
        do {
            return try ModelContainer(for: Schema(models), configurations: config)
        } catch {
            fatalError("Couldn't open the store: \(error)")
        }
    }

    /// First launch after the move to the app group: carry the old default store across
    /// (SQLite file plus its journal), so nothing logged so far is lost.
    private static func adoptDefaultStoreIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: url.path) else { return }
        let old = URL.applicationSupportDirectory.appendingPathComponent("default.store")
        guard fm.fileExists(atPath: old.path) else { return }
        try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        for suffix in ["", "-wal", "-shm"] {
            let from = URL(fileURLWithPath: old.path + suffix)
            let to = URL(fileURLWithPath: url.path + suffix)
            if fm.fileExists(atPath: from.path) { try? fm.copyItem(at: from, to: to) }
        }
    }
}
