import Foundation
import SwiftData
import WatchConnectivity
import WidgetKit

/// Phone side of the watch mirror. The phone owns the data; the watch shows a snapshot
/// of today and sends taps back here to be applied.
@MainActor final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    /// Set by the app; every incoming tap is applied to this container's main context.
    var container: ModelContainer?

    private override init() { super.init() }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends today's stops, counts, weights and set overrides. Cheap, so call it on every save.
    func push() {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated,
              let container else { return }
        let context = container.mainContext
        let start = Week.calendar.startOfDay(for: .now)
        let end = Week.calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let logs = (try? context.fetch(FetchDescriptor<StopLog>(
            predicate: #Predicate { $0.day >= start && $0.day < end }))) ?? []
        let configs = (try? context.fetch(FetchDescriptor<MoveConfig>())) ?? []
        try? WCSession.default.updateApplicationContext(
            WatchSnapshot(day: start, logs: logs, configs: configs).plist)
    }

    private func apply(_ message: [String: Any]) {
        guard let container,
              let stopID = message["stopID"] as? String,
              let moveName = message["moveName"] as? String,
              let count = message["count"] as? Int else { return }
        let context = container.mainContext
        let start = Week.calendar.startOfDay(for: .now)
        let end = Week.calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let logs = (try? context.fetch(FetchDescriptor<StopLog>(
            predicate: #Predicate { $0.stopID == stopID && $0.day >= start && $0.day < end }))) ?? []
        let log = logs.first ?? {
            let fresh = StopLog(day: start, stopID: stopID)
            context.insert(fresh)
            return fresh
        }()
        log.setCounts[moveName] = max(0, count)
        try? context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
        push()
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        Task { @MainActor in self.push() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in self.apply(message) }
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in self.apply(userInfo) }
    }
}

extension WatchSnapshot {
    @MainActor init(day: Date, logs: [StopLog], configs: [MoveConfig]) {
        self.day = day
        stops = logs.map { Stop(stopID: $0.stopID, setCounts: $0.setCounts, weights: $0.weights, notes: $0.notes) }
        sets = [:]; weights = [:]
        for c in configs {
            if let s = c.sets { sets[Self.key(c.stopID, c.moveName)] = s }
            if let w = c.weight { weights[Self.key(c.stopID, c.moveName)] = w }
        }
    }
}
