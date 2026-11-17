import SwiftData
import SwiftUI
import WatchKit

struct WatchHomeView: View {
    @Environment(WorkoutManager.self) private var workout
    @Query private var logs: [StopLog]

    private func isDoneToday(_ stop: WeekStop) -> Bool {
        logs.contains { $0.stopID == stop.id && $0.isStarted && Week.calendar.isDateInToday($0.day) }
    }

    var body: some View {
        List(WeekStop.all) { stop in
            NavigationLink(value: stop.id) {
                HStack(spacing: 10) {
                    StopIcon(symbol: isDoneToday(stop) ? "checkmark" : stop.symbol, size: 16, weight: .regular)
                        .foregroundStyle(isDoneToday(stop) ? EnkrateiaPalette.gold : EnkrateiaPalette.clay)
                        .frame(width: 26)
                    Text(stop.name)
                        .foregroundStyle(EnkrateiaPalette.parchment)
                    Spacer(minLength: 0)
                    if workout.activeStopID == stop.id {
                        Image(systemName: "record.circle")
                            .foregroundStyle(EnkrateiaPalette.gold)
                            .accessibilityLabel("Workout running")
                    }
                }
            }
        }
        .navigationTitle("Today")
        .navigationDestination(for: String.self) { id in
            if let stop = WeekStop.named(id) { WatchStopView(stop: stop) }
        }
    }
}

struct WatchStopView: View {
    let stop: WeekStop

    @Environment(\.modelContext) private var context
    @Environment(WorkoutManager.self) private var workout
    @Query private var logs: [StopLog]
    @Query private var configs: [MoveConfig]

    private var log: StopLog? {
        logs.first { $0.stopID == stop.id && Week.calendar.isDateInToday($0.day) }
    }

    private func sets(for move: Move) -> Int {
        MoveConfig.find(stop.id, move.name, in: configs)?.sets ?? move.sets
    }

    var body: some View {
        List {
            Section { workoutRow }
            ForEach(stop.moves) { move in
                Button { advance(move) } label: {
                    WatchMoveRow(move: move,
                                 sets: sets(for: move),
                                 done: log?.setCounts[move.name] ?? 0,
                                 weight: log?.weights[move.name]
                                    ?? MoveConfig.find(stop.id, move.name, in: configs)?.weight)
                }
            }
        }
        .navigationTitle(stop.name)
    }

    @ViewBuilder private var workoutRow: some View {
        if workout.activeStopID == stop.id, let start = workout.startDate {
            Button {
                Task { await workout.end() }
            } label: {
                HStack {
                    Text(timerInterval: start...Date.distantFuture, countsDown: false)
                        .monospacedDigit()
                        .foregroundStyle(EnkrateiaPalette.gold)
                    Spacer()
                    Text("END").font(.footnote.bold()).foregroundStyle(EnkrateiaPalette.clay)
                }
            }
            .disabled(workout.isBusy)
        } else {
            Button {
                Task { await workout.start(stop) }
            } label: {
                Label(workout.activeStopID == nil ? "Start workout" : "Another stop is running",
                      systemImage: "play.fill")
                    .foregroundStyle(EnkrateiaPalette.gold)
            }
            .disabled(workout.activeStopID != nil || workout.isBusy)
        }
        if let error = workout.errorMessage {
            Text(error).font(.footnote).foregroundStyle(EnkrateiaPalette.clay)
        }
    }

    /// Each tap checks one more set; tapping a finished move clears it, so a mistap is recoverable.
    private func advance(_ move: Move) {
        let current: StopLog
        if let log {
            current = log
        } else {
            current = StopLog(day: Week.calendar.startOfDay(for: .now), stopID: stop.id)
            context.insert(current)
        }
        let done = current.setCounts[move.name] ?? 0
        current.setCounts[move.name] = done >= sets(for: move) ? 0 : done + 1
        try? context.save()
        WKInterfaceDevice.current().play(.click)
    }
}

private struct WatchMoveRow: View {
    let move: Move
    let sets: Int
    let done: Int
    let weight: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(move.name)
                    .font(.headline)
                    .foregroundStyle(EnkrateiaPalette.parchment)
                Spacer(minLength: 4)
                if let weight {
                    Text(weight == weight.rounded() ? "\(Int(weight)) lb" : "\(weight) lb")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(EnkrateiaPalette.gold)
                }
            }
            Text(move.detail)
                .font(.footnote)
                .foregroundStyle(EnkrateiaPalette.bronze)
            HStack(spacing: 4) {
                ForEach(0..<sets, id: \.self) { i in
                    Capsule()
                        .fill(i < done ? EnkrateiaPalette.gold : .clear)
                        .overlay(Capsule().stroke(i < done ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze, lineWidth: 1))
                        .frame(maxWidth: .infinity)
                        .frame(height: 10)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(done) of \(sets) sets done")
    }
}
