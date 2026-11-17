import Foundation

/// What the watch gets: today's stops as plain dictionaries, so it needs no SwiftData.
struct WatchSnapshot {
    var day: Date
    var stops: [Stop]
    var sets: [String: Int]        // "stopID/move" -> override
    var weights: [String: Double]  // "stopID/move" -> last weight

    struct Stop {
        var stopID: String
        var setCounts: [String: Int]
        var weights: [String: Double]
        var notes: String
        var isStarted: Bool { setCounts.values.contains { $0 > 0 } || !notes.isEmpty }
    }

    static func key(_ stopID: String, _ move: String) -> String { "\(stopID)/\(move)" }

    func sets(for move: Move, in stopID: String) -> Int { sets[Self.key(stopID, move.name)] ?? move.sets }

    func weight(for move: Move, in stopID: String) -> Double? {
        stops.first { $0.stopID == stopID }?.weights[move.name] ?? weights[Self.key(stopID, move.name)]
    }

    var plist: [String: Any] {
        ["day": day,
         "stops": stops.map { ["stopID": $0.stopID, "setCounts": $0.setCounts, "weights": $0.weights, "notes": $0.notes] },
         "sets": sets, "weights": weights]
    }

    init(day: Date, stops: [Stop], sets: [String: Int], weights: [String: Double]) {
        self.day = day; self.stops = stops; self.sets = sets; self.weights = weights
    }

    init?(plist: [String: Any]) {
        guard let day = plist["day"] as? Date, let raw = plist["stops"] as? [[String: Any]] else { return nil }
        self.day = day
        stops = raw.compactMap { s in
            guard let id = s["stopID"] as? String else { return nil }
            return Stop(stopID: id,
                        setCounts: s["setCounts"] as? [String: Int] ?? [:],
                        weights: s["weights"] as? [String: Double] ?? [:],
                        notes: s["notes"] as? String ?? "")
        }
        sets = plist["sets"] as? [String: Int] ?? [:]
        weights = plist["weights"] as? [String: Double] ?? [:]
    }
}
