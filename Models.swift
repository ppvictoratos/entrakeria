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
        .init("Kettlebell Swings", label: "KB Swings", sets: 3, "3 × 10 · Explosive hip drive",
              symbol: "figure.strengthtraining.functional"),
        .init("Medicine Ball Rotational Throws", label: "Med Ball Throws", sets: 3,
              "3 × 8 per side · Golf power translation", symbol: "figure.golf"),
        .init("Bodyweight Pull-Ups (Speed)", label: "Speed Pull-Ups", sets: 4,
              "4 × 5 · Explosive up, 2-sec lower", symbol: "figure.climbing"),
        .init("Kettlebell Goblet Squats", label: "Goblet Squats", sets: 3, "3 × 12",
              symbol: "figure.strengthtraining.functional")
    ],
    // Day 2 — High Intensity & Heavy Load
    [
        .init("Weighted Pull-Ups", sets: 4, "4 × 4–6 · Dipping belt, heavy, 3-min rest",
              symbol: "figure.climbing"),
        .init("Conventional Barbell Deadlift", label: "Deadlift", sets: 3,
              "3 × 5 · Posterior chain foundation", symbol: "figure.strengthtraining.traditional"),
        .init("Overhead Barbell Press", label: "Overhead Press", sets: 3, "3 × 6",
              symbol: "figure.strengthtraining.traditional"),
        .init("Hanging Leg Raises", label: "Leg Raises", sets: 3, "3 × max · Strict control",
              symbol: "figure.core.training")
    ],
    // Day 3 — Active Recovery & Mobility
    [
        .session("Lap Swimming", label: "Swim", "20–30 min · Continuous, moderate pace",
                 symbol: "figure.pool.swim"),
        .session("Rotational Mobility & T-Spine Flow", label: "T-Spine Flow",
                 "15 min · Golf-swing mechanics", symbol: "figure.flexibility")
    ],
    // Day 4 — Structural Volume & Hypertrophy
    [
        .init("Chest-to-Bar Pull-Ups", label: "C2B Pull-Ups", sets: 3,
              "3 × 8–12 · Hard contraction hold at top", symbol: "figure.climbing"),
        .init("Barbell Back Squats", label: "Back Squats", sets: 3, "3 × 10",
              symbol: "figure.strengthtraining.traditional"),
        .init("Dumbbell Incline Bench Press", label: "Incline DB Press", sets: 3, "3 × 10",
              symbol: "figure.strengthtraining.traditional"),
        .init("Landmine Core Twists", label: "Landmine Twists", sets: 3, "3 × 12 per side",
              symbol: "figure.core.training")
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
    init(day: Date, stopID: String) { self.day = day; self.stopID = stopID; setCounts = [:] }

    var isStarted: Bool { setCounts.values.contains { $0 > 0 } || !notes.isEmpty }
}

/// One Save My Back item ticked on a given day.
@Model final class BackCheck {
    var day: Date
    var itemID: String
    init(day: Date, itemID: String) { self.day = day; self.itemID = itemID }
}
