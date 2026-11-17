import Foundation
import Observation
import WatchConnectivity

/// The watch keeps no data of its own: it shows the phone's snapshot of today and sends
/// every tap back. The last snapshot is kept in UserDefaults so a cold start isn't blank.
@MainActor @Observable final class PhoneMirror: NSObject, WCSessionDelegate {
    private(set) var snapshot: WatchSnapshot?
    private static let cacheKey = "phoneSnapshot"

    override init() {
        super.init()
        if let cached = UserDefaults.standard.dictionary(forKey: Self.cacheKey) {
            snapshot = WatchSnapshot(plist: cached)
        }
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Today's snapshot, or nothing if the phone's last word was about another day.
    var today: WatchSnapshot? {
        guard let snapshot, Week.calendar.isDateInToday(snapshot.day) else { return nil }
        return snapshot
    }

    func stop(_ stopID: String) -> WatchSnapshot.Stop? { today?.stops.first { $0.stopID == stopID } }

    /// Updates the local copy right away, then tells the phone.
    func tick(stopID: String, move: String, count: Int) {
        var snap = today ?? WatchSnapshot(day: Week.calendar.startOfDay(for: .now), stops: [], sets: [:], weights: [:])
        if let i = snap.stops.firstIndex(where: { $0.stopID == stopID }) {
            snap.stops[i].setCounts[move] = count
        } else {
            snap.stops.append(.init(stopID: stopID, setCounts: [move: count], weights: [:], notes: ""))
        }
        store(snap)
        let message: [String: Any] = ["stopID": stopID, "moveName": move, "count": count]
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { _ in session.transferUserInfo(message) }
        } else {
            session.transferUserInfo(message)
        }
    }

    private func store(_ snap: WatchSnapshot) {
        snapshot = snap
        UserDefaults.standard.set(snap.plist, forKey: Self.cacheKey)
    }

    private func receive(_ context: [String: Any]) {
        if let snap = WatchSnapshot(plist: context) { store(snap) }
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        let context = session.receivedApplicationContext
        Task { @MainActor in self.receive(context) }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        Task { @MainActor in self.receive(context) }
    }
}
