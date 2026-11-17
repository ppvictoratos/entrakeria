import Foundation

/// No UI or storage in here, so the watch app can share it.
struct Move: Identifiable {
    let name: String
    let detail: String
    let symbol: String
    var sets = 1
    /// True for moves where the load matters, so the card shows a weight field.
    var weighted = false

    var id: String { name }

    /// The five-minute pre-workout warm-up, shared by the lifting stops.
    static let warmUp: [Move] = [
        .init(name: "Cat-cow", detail: "10 reps · Warm-up", symbol: "figure.yoga"),
        .init(name: "Hip flexor stretch", detail: "30 sec per side · Warm-up", symbol: "figure.flexibility"),
        .init(name: "Glute bridge", detail: "15 reps · Warm-up", symbol: "figure.core.training"),
        .init(name: "Bird-dog", detail: "5 per side · Warm-up", symbol: "figure.core.training"),
        .init(name: "Squat to depth", detail: "10 reps · Bodyweight · Warm-up", symbol: "figure.strengthtraining.functional")
    ]
}

struct WeekStop: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let tagline: String
    var isBonus = false
    let moves: [Move]

    static func named(_ id: String) -> WeekStop? { all.first { $0.id == id } }

    static let all: [WeekStop] = [swim, machines, kayak, homelift, hike, morningStretch, core]
    static let goal = all.filter { !$0.isBonus }.count

    static let swim = WeekStop(
        id: "swim", name: "Swim", symbol: "figure.pool.swim", tagline: "50–60 min · Breaks are fine",
        moves: [
            .init(name: "Warm-up", detail: "10 min · Easy mix of strokes and drills", symbol: "figure.pool.swim"),
            .init(name: "Longer sets", detail: "3 × 10 min · Steady pace, rest 1–2 min between",
                  symbol: "figure.pool.swim", sets: 3),
            .init(name: "Sprints", detail: "6 × 25 yd · Fast, full rest between",
                  symbol: "bolt.fill", sets: 6),
            .init(name: "Water weights", detail: "3 × 12 · Chest deep, slow and controlled",
                  symbol: "dumbbell.fill", sets: 3, weighted: true),
            .init(name: "Water lunges", detail: "3 × 10 per leg · Tall posture",
                  symbol: "figure.water.fitness", sets: 3),
            .init(name: "Cool-down", detail: "5 min · Easy laps", symbol: "figure.pool.swim")
        ])

    static let machines = WeekStop(
        id: "machines", name: "Gym", symbol: "dumbbell.fill", tagline: "Warm up, then glutes first",
        moves: Move.warmUp + [
            .init(name: "Hip abduction", detail: "3 × 12 · Push out from the glutes",
                  symbol: "figure.strengthtraining.functional", sets: 3, weighted: true),
            .init(name: "Leg squat machine", detail: "3 × 10 · Hips and back stay on the pad",
                  symbol: "figure.strengthtraining.functional", sets: 3, weighted: true),
            .init(name: "Hip adduction", detail: "3 × 12 · Slow and controlled",
                  symbol: "figure.strengthtraining.functional", sets: 3, weighted: true),
            .init(name: "Lat pulldown", detail: "4 × 10", symbol: "figure.strengthtraining.traditional", sets: 4, weighted: true),
            .init(name: "Chest press", detail: "4 × 10", symbol: "figure.strengthtraining.traditional", sets: 4, weighted: true),
            .init(name: "Pec fly", detail: "3 × 12", symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true),
            .init(name: "Rear delt fly", detail: "3 × 12 · Same machine as pec fly, facing in",
                  symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true),
            .init(name: "Incline overhead press", detail: "3 × 10 · Back on the pad, ribs down",
                  symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true),
            .init(name: "Biceps curl machine", detail: "3 × 12 · Slow on the way down",
                  symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true)
        ])

    static let kayak = WeekStop(
        id: "kayak", name: "Kayak", symbol: "entrakeria.kayak", tagline: "Out on the water",
        moves: [.init(name: "Paddle", detail: "As long as your back says yes · Sit tall, take stretch breaks",
                      symbol: "entrakeria.kayak")])

    static let homelift = WeekStop(
        id: "homelift", name: "Homelift", symbol: "house.fill", tagline: "Warm up · 12 lb KB for safety",
        moves: Move.warmUp + [
            .init(name: "Banded side walk", detail: "3 × 10 per side · Band above the knees",
                  symbol: "figure.walk", sets: 3),
            .init(name: "Block squeeze bridge", detail: "3 × 12 · Yoga block between knees, 2 sec squeeze",
                  symbol: "figure.core.training", sets: 3),
            .init(name: "KB RDL", detail: "4 × 8 · 12 lb · Neutral spine",
                  symbol: "figure.strengthtraining.functional", sets: 4, weighted: true),
            .init(name: "Goblet squat", detail: "4 × 8 · 12 lb · Slow tempo",
                  symbol: "figure.strengthtraining.functional", sets: 4, weighted: true),
            .init(name: "Reverse lunges", detail: "3 × 10 per leg · 15 lb DBs",
                  symbol: "figure.strengthtraining.functional", sets: 3, weighted: true),
            .init(name: "Suitcase carry", detail: "4 rounds · 12 lb · Switch hands",
                  symbol: "figure.walk", sets: 4, weighted: true),
            .init(name: "Chin-ups", detail: "4 × AMRAP · Stop 1–2 short of failure",
                  symbol: "figure.climbing", sets: 4),
            .init(name: "DB curl", detail: "3 × 10 · 15 lb DBs · Slow on the way down",
                  symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true),
            .init(name: "Side plank", detail: "3 × 30 sec per side", symbol: "figure.core.training", sets: 3)
        ])

    static let hike = WeekStop(
        id: "hike", name: "Hike", symbol: "figure.hiking", tagline: "Good for the mind",
        moves: [.init(name: "Hike", detail: "No pace to hit. Just go.", symbol: "figure.hiking")])

    static let morningStretch = WeekStop(
        id: "morning", name: "Morning", symbol: "sunrise.fill", tagline: "Floor reset · Every day",
        isBonus: true,
        moves: [
            .init(name: "Pelvic tilts",   detail: "29 slow reps · Flat back",         symbol: "figure.flexibility"),
            .init(name: "Glute bridges",  detail: "2 × 12 · 2 sec squeeze",           symbol: "figure.core.training", sets: 2),
            .init(name: "Ham bridges",    detail: "2 × 12 · 2 sec squeeze",           symbol: "figure.core.training", sets: 2),
            .init(name: "Clamshells",     detail: "2 × 20 each side",                 symbol: "figure.strengthtraining.functional", sets: 2),
            .init(name: "Leg lifts",      detail: "2 × 10 each side · Lateral",       symbol: "figure.strengthtraining.functional", sets: 2),
            .init(name: "Child's pose",   detail: "60 sec",                           symbol: "figure.yoga"),
        ])

    static let core = WeekStop(
        id: "core", name: "Core", symbol: "figure.core.training", tagline: "Spine-safe · Any day",
        isBonus: true,
        moves: [
            .init(name: "Curl-up",        detail: "2 × 10 each side · McGill, hands under low back", symbol: "figure.core.training", sets: 2),
            .init(name: "Side plank",     detail: "3 × 30 sec per side · McGill",           symbol: "figure.core.training", sets: 3),
            .init(name: "Bird-dog",       detail: "3 × 5 per side · McGill, slow",          symbol: "figure.core.training", sets: 3),
            .init(name: "Dead bug",       detail: "3 × 8 each side · Opposite arm and leg", symbol: "figure.core.training", sets: 3),
            .init(name: "Cat-cow",        detail: "3 × 10",                                 symbol: "figure.yoga", sets: 3),
            .init(name: "Pigeon",         detail: "60 sec each side",                       symbol: "figure.flexibility"),
            .init(name: "90/90 hip",      detail: "60 sec each side",                       symbol: "figure.flexibility"),
            .init(name: "Dead hang",      detail: "30–60 sec · Decompression",              symbol: "figure.climbing"),
        ])
}

/// Weeks run Monday to Sunday and start out blank.
enum Week {
    static let calendar: Calendar = {
        var c = Calendar.current
        c.firstWeekday = 2
        return c
    }()

    static func days(containing date: Date) -> [Date] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
}

// MARK: - Save My Back

struct BackItem: Identifiable {
    let id: String
    let name: String
    let detail: String
    let symbol: String
}

enum SaveMyBack {
    static let move: [BackItem] = [
        .init(id: "walk", name: "Get up and walk", detail: "5 min", symbol: "figure.walk"),
        .init(id: "big3", name: "McGill Big 3", detail: "1 set each · Curl-up, side plank, bird-dog", symbol: "figure.core.training"),
        .init(id: "bridge", name: "Glute bridges", detail: "15 reps · 2 sec squeeze", symbol: "figure.cooldown")
    ]
    static let rest: [BackItem] = [
        .init(id: "legs", name: "Legs up", detail: "10 min", symbol: "bed.double.fill"),
        .init(id: "ice", name: "Ice", detail: "15 min · Towel between ice and skin", symbol: "snowflake"),
        .init(id: "heat", name: "Heat", detail: "15 min", symbol: "flame"),
        .init(id: "stand", name: "Standing desk", detail: "Next time you've been sitting a while", symbol: "figure.stand")
    ]
}
