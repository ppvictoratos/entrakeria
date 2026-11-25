import Foundation

/// No UI or storage in here, so the watch app can share it.
struct Move: Identifiable {
    let name: String
    let detail: String
    let symbol: String
    var sets = 1
    /// True for moves where the load matters, so the card shows a weight field.
    var weighted = false
    /// Header the move sits under on a long stop; empty for short ones.
    var section = ""

    var id: String { name }

    /// The five-minute pre-workout warm-up, shared by the lifting buckets.
    static let warmUp: [Move] = [
        .init(name: "Hip circles", detail: "10 each way · Standing, no bending", symbol: "figure.flexibility", section: "Warm-up"),
        .init(name: "Hip flexor stretch", detail: "30 sec per side", symbol: "figure.flexibility", section: "Warm-up"),
        .init(name: "Glute bridge", detail: "15 reps", symbol: "figure.core.training", section: "Warm-up"),
        .init(name: "Bird-dog", detail: "5 per side", symbol: "figure.core.training", section: "Warm-up"),
        .init(name: "Squat to depth", detail: "10 reps · Bodyweight", symbol: "figure.strengthtraining.functional", section: "Warm-up")
    ]
}

struct WeekStop: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let tagline: String
    var isBonus = false
    /// True when the same stop can be placed on a day more than once (two hikes, say).
    var allowsRepeats = false
    /// True for stops that take a place name, a rating and the dog.
    var isOutdoors = false
    let moves: [Move]

    /// Stop ids from earlier layouts, so old logs still land somewhere.
    static let legacyIDs: [String: String] = [
        "homelift": "machines", "hike": "nature", "kayak": "nature"
    ]

    /// The chips across the top of the home screen.
    static let all: [WeekStop] = [morningStretch, swim, machines, nature]

    /// Gym buckets, placed from the Gym chip by long-press. Each is its own stop on a day.
    static let buckets: [WeekStop] = [upper, lower, core]

    static let goal = all.filter { !$0.isBonus }.count

    static func named(_ id: String) -> WeekStop? {
        let canonical = legacyIDs[id] ?? id
        return (all + buckets).first { $0.id == canonical }
    }

    /// Stop ids whose logs count toward this chip. The full gym also counts its upper and lower buckets.
    var placementIDs: [String] {
        id == "machines" ? ["machines", "upper", "lower"] : [id]
    }

    /// Move names in this stop, grouped under section headers in order.
    var sections: [(title: String, moves: [Move])] {
        var out: [(String, [Move])] = []
        for move in moves {
            if let last = out.indices.last, out[last].0 == move.section {
                out[last].1.append(move)
            } else {
                out.append((move.section, [move]))
            }
        }
        return out.map { (title: $0.0, moves: $0.1) }
    }

    static let morningStretch = WeekStop(
        id: "morning", name: "Morning", symbol: "sunrise.fill", tagline: "Floor reset · Every day",
        moves: [
            .init(name: "Pelvic tilts",   detail: "29 slow reps · Flat back",         symbol: "figure.flexibility"),
            .init(name: "Glute bridges",  detail: "2 × 12 · 2 sec squeeze",           symbol: "figure.core.training", sets: 2),
            .init(name: "Ham bridges",    detail: "2 × 12 · 2 sec squeeze",           symbol: "figure.core.training", sets: 2),
            .init(name: "Clamshells",     detail: "2 × 20 each side",                 symbol: "figure.strengthtraining.functional", sets: 2),
            .init(name: "Leg lifts",      detail: "2 × 10 each side · Lateral",       symbol: "figure.strengthtraining.functional", sets: 2),
            .init(name: "Figure-4 stretch", detail: "60 sec each side · On your back",  symbol: "figure.flexibility"),
        ])

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

    /// The whole gym: upper and lower. Core is its own bucket.
    static let machines = WeekStop(
        id: "machines", name: "Gym", symbol: "dumbbell.fill", tagline: "Warm up · Glutes first · Neutral spine",
        moves: Move.warmUp + upperMoves + lowerMoves)

    static let upper = WeekStop(
        id: "upper", name: "Upper", symbol: "figure.strengthtraining.traditional",
        tagline: "Pull · Press · Arms", allowsRepeats: true,
        moves: Move.warmUp + upperMoves)

    static let lower = WeekStop(
        id: "lower", name: "Lower", symbol: "figure.strengthtraining.functional",
        tagline: "Glutes · Hinge · Legs", allowsRepeats: true,
        moves: Move.warmUp + lowerMoves)

    /// Bands, the 12 and 25 lb kettlebells, two 15 lb dumbbells, two yoga blocks and the pull-up bar.
    static let core = WeekStop(
        id: "core", name: "Core", symbol: "figure.core.training",
        tagline: "Bands · Bar · Ends with the bag", allowsRepeats: true,
        moves: [
            .init(name: "Front plank",    detail: "3 × 30 sec · Long line, no sag",         symbol: "figure.core.training", sets: 3, section: "Core"),
            .init(name: "Side plank",     detail: "3 × 30 sec per side · McGill",           symbol: "figure.core.training", sets: 3, section: "Core"),
            .init(name: "Bird-dog holds", detail: "3 × 5 per side · McGill, slow",          symbol: "figure.core.training", sets: 3, section: "Core"),
            .init(name: "Dead bug",       detail: "3 × 8 each side · Opposite arm and leg", symbol: "figure.core.training", sets: 3, section: "Core"),
            .init(name: "Band Pallof press", detail: "3 × 10 per side · Band at chest, resist the pull",
                  symbol: "figure.core.training", sets: 3, section: "Core"),
            .init(name: "Suitcase carry", detail: "4 rounds · 12 or 25 lb kettlebell · Switch hands",
                  symbol: "figure.walk", sets: 4, weighted: true, section: "Core"),
            .init(name: "Dead hang",      detail: "30–60 sec · Pull-up bar, decompression", symbol: "figure.climbing", section: "Core"),
            .init(name: "Pigeon",         detail: "60 sec each side",                       symbol: "figure.flexibility", section: "Core"),
            .init(name: "90/90 hip",      detail: "60 sec each side",                       symbol: "figure.flexibility", section: "Core"),
            .init(name: "Speed bag",      detail: "30 sec · Boxing ritual, end of session", symbol: "figure.boxing", section: "Finisher")
        ])

    static let nature = WeekStop(
        id: "nature", name: "Outside", symbol: "figure.hiking", tagline: "Good for the mind",
        allowsRepeats: true, isOutdoors: true,
        moves: [
            .init(name: "Hike", detail: "No pace to hit. Just go.", symbol: "figure.hiking"),
            .init(name: "Dog walk", detail: "Out with the dog · Around the block or a trail", symbol: "dog.fill"),
            .init(name: "Paddle", detail: "As long as your back says yes · Sit tall, take stretch breaks",
                  symbol: "entrakeria.kayak")
        ])

    // MARK: - Gym buckets

    private static let upperMoves: [Move] = [
        .init(name: "Lat pulldown", detail: "4 × 10", symbol: "figure.strengthtraining.traditional", sets: 4, weighted: true, section: "Machines"),
        .init(name: "Chest press", detail: "4 × 10", symbol: "figure.strengthtraining.traditional", sets: 4, weighted: true, section: "Machines"),
        .init(name: "Pec fly", detail: "3 × 12", symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Rear delt fly", detail: "3 × 12 · Same machine as pec fly, facing in",
              symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Incline overhead press", detail: "3 × 10 · Back on the pad, ribs down",
              symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Biceps curl machine", detail: "3 × 12 · Slow on the way down",
              symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Chin-ups", detail: "4 × AMRAP · Stop 1–2 short of failure",
              symbol: "figure.climbing", sets: 4, section: "Home lift"),
        .init(name: "DB curl", detail: "3 × 10 · 15 lb DBs · Slow on the way down",
              symbol: "figure.strengthtraining.traditional", sets: 3, weighted: true, section: "Home lift")
    ]

    private static let lowerMoves: [Move] = [
        .init(name: "Hip abduction", detail: "3 × 12 · Push out from the glutes",
              symbol: "figure.strengthtraining.functional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Leg squat machine", detail: "3 × 10 · Hips and back stay on the pad",
              symbol: "figure.strengthtraining.functional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Hip adduction", detail: "3 × 12 · Slow and controlled",
              symbol: "figure.strengthtraining.functional", sets: 3, weighted: true, section: "Machines"),
        .init(name: "Banded side walk", detail: "3 × 10 per side · Band above the knees",
              symbol: "figure.walk", sets: 3, section: "Home lift"),
        .init(name: "Block squeeze bridge", detail: "3 × 12 · Yoga block between knees, 2 sec squeeze",
              symbol: "figure.core.training", sets: 3, section: "Home lift"),
        .init(name: "Single-leg glute bridge", detail: "3 × 10 each leg · 2 sec squeeze · No bending",
              symbol: "figure.core.training", sets: 3, section: "Home lift"),
        .init(name: "Goblet squat", detail: "4 × 8 · 12 lb · Slow tempo",
              symbol: "figure.strengthtraining.functional", sets: 4, weighted: true, section: "Home lift"),
        .init(name: "Reverse lunges", detail: "3 × 10 per leg · 15 lb DBs",
              symbol: "figure.strengthtraining.functional", sets: 3, weighted: true, section: "Home lift")
    ]
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
        .init(id: "big3", name: "Core reset", detail: "1 set each · Side plank, bird-dog, dead bug", symbol: "figure.core.training"),
        .init(id: "bridge", name: "Glute bridges", detail: "15 reps · 2 sec squeeze", symbol: "figure.cooldown")
    ]
    static let rest: [BackItem] = [
        .init(id: "legs", name: "Legs up", detail: "10 min", symbol: "bed.double.fill"),
        .init(id: "ice", name: "Ice", detail: "15 min · Towel between ice and skin", symbol: "snowflake"),
        .init(id: "heat", name: "Heat", detail: "15 min", symbol: "flame"),
        .init(id: "stand", name: "Standing desk", detail: "Next time you've been sitting a while", symbol: "figure.stand")
    ]
}
