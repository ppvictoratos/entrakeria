import SwiftData
import SwiftUI
import WidgetKit

/// What the widget shows: today's first placed stop and where each move stands.
struct TodayEntry: TimelineEntry {
    let date: Date
    let stopID: String?
    let done: [String: Int]
    let sets: [String: Int]      // overrides from MoveConfig, by move name

    var stop: WeekStop? { stopID.flatMap(WeekStop.named) }

    func sets(for move: Move) -> Int { sets[move.name] ?? move.sets }
    func done(for move: Move) -> Int { done[move.name] ?? 0 }

    static let placeholder = TodayEntry(date: .now, stopID: "machines",
                                        done: ["Cat-cow": 1], sets: [:])
}

struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(context.isPreview ? .placeholder : load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        // Refresh at midnight so a new day starts blank; set taps reload on their own.
        let start = Week.calendar.startOfDay(for: .now)
        let midnight = Week.calendar.date(byAdding: .day, value: 1, to: start) ?? .now
        completion(Timeline(entries: [load()], policy: .after(midnight)))
    }

    private func load() -> TodayEntry {
        let context = ModelContext(SharedStore.container())
        let start = Week.calendar.startOfDay(for: .now)
        let end = Week.calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let logs = (try? context.fetch(FetchDescriptor<StopLog>(
            predicate: #Predicate { $0.day >= start && $0.day < end }))) ?? []
        // Prefer a stop with work still open; else whatever is placed first.
        let log = logs.first { log in
            guard let stop = WeekStop.named(log.stopID) else { return false }
            return stop.moves.contains { (log.setCounts[$0.name] ?? 0) < $0.sets }
        } ?? logs.first
        guard let log, let stop = WeekStop.named(log.stopID) else {
            return TodayEntry(date: .now, stopID: nil, done: [:], sets: [:])
        }
        let configs = (try? context.fetch(FetchDescriptor<MoveConfig>())) ?? []
        var sets: [String: Int] = [:]
        for move in stop.moves {
            if let s = MoveConfig.find(stop.id, move.name, in: configs)?.sets { sets[move.name] = s }
        }
        return TodayEntry(date: .now, stopID: stop.id, done: log.setCounts, sets: sets)
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStore.widgetKind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(EnkrateiaPalette.bg, for: .widget)
        }
        .configurationDisplayName("Today's stop")
        .description("Tick off sets without opening the app.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    private var limit: Int { family == .systemLarge ? 7 : 3 }

    /// The moves still open, in order, plus the last finished one for context when there's room.
    private var moves: [Move] {
        guard let stop = entry.stop else { return [] }
        let open = stop.moves.filter { entry.done(for: $0) < entry.sets(for: $0) }
        return Array(open.prefix(limit))
    }

    var body: some View {
        if let stop = entry.stop {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(stop.name.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(2)
                        .foregroundStyle(EnkrateiaPalette.gold)
                    Spacer()
                    Text(progress(stop))
                        .font(.system(size: 10, weight: .medium).monospacedDigit())
                        .kerning(1)
                        .foregroundStyle(EnkrateiaPalette.bronze)
                }
                if moves.isEmpty {
                    Spacer()
                    Text("All done. Nice.")
                        .font(.system(size: 14).italic())
                        .foregroundStyle(EnkrateiaPalette.bronze)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    ForEach(moves) { move in
                        WidgetMoveRow(stopID: stop.id, move: move,
                                      sets: entry.sets(for: move), done: entry.done(for: move))
                    }
                    Spacer(minLength: 0)
                }
            }
        } else {
            VStack(spacing: 6) {
                Text("ΕΝΤΡΑΚΕΡΙΑ")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
                    .kerning(4)
                    .foregroundStyle(EnkrateiaPalette.bronze)
                Text("Blank day. Pick a stop in the app.")
                    .font(.system(size: 13).italic())
                    .foregroundStyle(EnkrateiaPalette.bronze)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func progress(_ stop: WeekStop) -> String {
        let finished = stop.moves.filter { entry.done(for: $0) >= entry.sets(for: $0) }.count
        return "\(finished) / \(stop.moves.count)"
    }
}

private struct WidgetMoveRow: View {
    let stopID: String
    let move: Move
    let sets: Int
    let done: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                StopIcon(symbol: move.symbol, size: 12, weight: .regular)
                    .foregroundStyle(EnkrateiaPalette.clay)
                    .frame(width: 16)
                Text(move.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(EnkrateiaPalette.parchment)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text(move.detail.components(separatedBy: " · ").first ?? "")
                    .font(.system(size: 10))
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .lineLimit(1)
            }
            HStack(spacing: 4) {
                ForEach(0..<sets, id: \.self) { i in
                    Button(intent: TickSetIntent(stopID: stopID, moveName: move.name,
                                                 count: done == i + 1 ? i : i + 1)) {
                        Capsule()
                            .fill(i < done ? EnkrateiaPalette.gold : EnkrateiaPalette.gold.opacity(0.001))
                            .overlay(Capsule().stroke(i < done ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze, lineWidth: 1))
                            .frame(height: 14)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
