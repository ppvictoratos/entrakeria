import Foundation
import SwiftData

@Model final class TetradCycle {
    var startDate: Date
    @Relationship(deleteRule: .cascade) var sessions: [WorkoutSession]
    init(startDate: Date = .now) { self.startDate = startDate; sessions = [] }
}

@Model final class WorkoutSession {
    var dayIndex: Int          // 0...3, position in the tetrad
    var date: Date
    var totalDuration: TimeInterval
    @Relationship(deleteRule: .cascade) var logs: [ExerciseLog]
    init(dayIndex: Int, date: Date = .now) {
        self.dayIndex = dayIndex; self.date = date
        totalDuration = 0; logs = []
    }
}

@Model final class ExerciseLog {
    var exerciseName: String
    var reps: Int
    var duration: TimeInterval
    var completedAt: Date?
    init(exerciseName: String, reps: Int, duration: TimeInterval) {
        self.exerciseName = exerciseName; self.reps = reps; self.duration = duration
    }
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let label: String               // short form for the vertex box
    let target: Int                 // sets to lap through
    let detail: String              // the prescription, as written
    let stickFigureSymbol: String   // SF Symbol stand-in, swap later
    var countUnit = "SET"

    init(_ name: String, label: String? = nil, sets: Int, _ detail: String, symbol: String) {
        self.name = name; self.label = label ?? name
        target = sets; self.detail = detail; stickFigureSymbol = symbol
    }

    /// A single timed block (swim, mobility flow) rather than counted sets.
    static func session(_ name: String, label: String? = nil, _ detail: String, symbol: String) -> Exercise {
        var e = Exercise(name, label: label, sets: 1, detail, symbol: symbol)
        e.countUnit = "SESSION"
        return e
    }
}

// Backend-swappable tetrad: one list per day, indexed by WorkoutSession.dayIndex.
let defaultTetrad: [[Exercise]] = [
    // Day 1 — Preparation & CNS Priming
    [
        .init("Kettlebell Thrusters", label: "KB Thrusters", sets: 3,
              "3 × 8 · 12 lb · Squat, then press in one motion", symbol: "figure.strengthtraining.functional"),
        .init("Kettlebell Halo", label: "KB Halo", sets: 3,
              "3 × 5 each way · 12 lb · Standing, ribs down", symbol: "figure.strengthtraining.functional"),
        .init("Kettlebell Farmer Carry", label: "Farmer Carry", sets: 4,
              "4 × 40 yd · 12 lb each hand · Grip, tall posture", symbol: "figure.walk"),
        .init("Kettlebell Goblet Squats", label: "Goblet Squats", sets: 3,
              "3 × 10 · Hold 3 sec at the bottom", symbol: "figure.strengthtraining.functional")
    ],
    // Day 2 — High Intensity & Heavy Load
    [
        .init("Weighted Pull-Ups", sets: 4, "4 × 5 · Dipping belt, heavy, 3-min rest",
              symbol: "figure.climbing"),
        .init("Bulgarian Split Squat", label: "Split Squat", sets: 3,
              "3 × 8 per leg · 15 lb DBs · Tall torso", symbol: "figure.strengthtraining.functional"),
        .init("Standing Dumbbell Press", label: "DB Press", sets: 3,
              "3 × 8 · 15 lb DBs · Ribs down", symbol: "figure.strengthtraining.traditional"),
        .init("Single-Leg Glute Bridge", label: "Glute Bridge", sets: 3,
              "3 × 10 per leg · 2 sec squeeze", symbol: "figure.core.training")
    ],
    // Day 3 — Active Recovery & Mobility
    [
        .session("Lap Swimming", label: "Swim", "20–30 min · Continuous, moderate pace",
                 symbol: "figure.pool.swim"),
        .session("Hip & Thoracic Mobility", label: "Mobility",
                 "15 min · Open book, 90/90, pigeon · No bending", symbol: "figure.flexibility")
    ],
    // Day 4 — Structural Volume & Hypertrophy
    [
        .init("Chest-to-Bar Pull-Ups", label: "C2B Pull-Ups", sets: 3,
              "3 × 8–12 · Hard contraction hold at top", symbol: "figure.climbing"),
        .init("Deep Squat Hold", label: "Squat Hold", sets: 3,
              "3 × 45 sec · Heels down, chest up, breathe", symbol: "figure.strengthtraining.functional"),
        .init("Dumbbell Incline Bench Press", label: "Incline DB Press", sets: 3, "3 × 10",
              symbol: "figure.strengthtraining.traditional"),
        .init("Pallof Press", label: "Pallof Press", sets: 3,
              "3 × 10 per side · Band at chest, resist the pull", symbol: "figure.core.training")
    ]
]

// MARK: - My week

/// A stop placed on a calendar day, with the sets checked off so far.
@Model final class StopLog {
    var day: Date
    var stopID: String
    var setCounts: [String: Int]
    var notes: String = ""
    var placeName: String?
    var latitude: Double?
    var longitude: Double?
    var rating: Int = 0
    var dogCame: Bool = false
    /// Weight used that day, per move name. Empty means "whatever the move's config says".
    var weights: [String: Double] = [:]
    /// Set when the session is saved. A saved session's sets are locked against accidental taps until unlocked.
    var savedAt: Date?
    init(day: Date, stopID: String) { self.day = day; self.stopID = stopID; setCounts = [:] }

    var isStarted: Bool { setCounts.values.contains { $0 > 0 } || !notes.isEmpty }
}

/// One Save My Back item ticked on a given day.
@Model final class BackCheck {
    var day: Date
    var itemID: String
    init(day: Date, itemID: String) { self.day = day; self.itemID = itemID }
}

/// Your own tweaks to a move: how many sets you actually do, and the weight you're on.
/// One per (stop, move); absent means the defaults in WeekPlan.
@Model final class MoveConfig {
    var stopID: String
    var moveName: String
    var sets: Int?
    var weight: Double?
    init(stopID: String, moveName: String) { self.stopID = stopID; self.moveName = moveName }

    static func find(_ stopID: String, _ moveName: String, in configs: [MoveConfig]) -> MoveConfig? {
        configs.first { $0.stopID == stopID && $0.moveName == moveName }
    }
}
