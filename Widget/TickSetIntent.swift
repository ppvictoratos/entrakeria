import AppIntents
import SwiftData
import WidgetKit

/// Sets a move's checked-set count for today, from a pill on the widget.
struct TickSetIntent: AppIntent {
    static var title: LocalizedStringResource = "Tick a set"
    static var description = IntentDescription("Checks off a set on today's stop.")

    @Parameter(title: "Stop") var stopID: String
    @Parameter(title: "Move") var moveName: String
    @Parameter(title: "Sets done") var count: Int

    init() { stopID = ""; moveName = ""; count = 0 }
    init(stopID: String, moveName: String, count: Int) {
        self.stopID = stopID; self.moveName = moveName; self.count = count
    }

    func perform() async throws -> some IntentResult {
        let context = ModelContext(SharedStore.container())
        let start = Week.calendar.startOfDay(for: .now)
        let end = Week.calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let id = stopID
        let logs = try context.fetch(FetchDescriptor<StopLog>(
            predicate: #Predicate { $0.stopID == id && $0.day >= start && $0.day < end }))
        let log: StopLog
        if let first = logs.first {
            log = first
        } else {
            log = StopLog(day: start, stopID: id)
            context.insert(log)
        }
        log.setCounts[moveName] = max(0, count)
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
        return .result()
    }
}
