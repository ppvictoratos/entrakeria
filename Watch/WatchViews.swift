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

    private var log: StopLog? {
        logs.first { $0.stopID == stop.id && Week.calendar.isDateInToday($0.day) }
    }

    var body: some View {
        List {
            Section { workoutRow }
            ForEach(stop.moves) { move in
                Button { advance(move) } label: {
                    WatchMoveRow(move: move, done: log?.setCounts[move.name] ?? 0)
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
        current.setCounts[move.name] = done >= move.sets ? 0 : done + 1
        try? context.save()
        WKInterfaceDevice.current().play(.click)
    }
}

private struct WatchMoveRow: View {
    let move: Move
    let done: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(move.name)
                .font(.headline)
                .foregroundStyle(EnkrateiaPalette.parchment)
            Text(move.detail)
                .font(.footnote)
                .foregroundStyle(EnkrateiaPalette.bronze)
            HStack(spacing: 5) {
                ForEach(0..<move.sets, id: \.self) { i in
                    Circle()
                        .fill(i < done ? EnkrateiaPalette.gold : .clear)
                        .overlay(Circle().stroke(i < done ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze, lineWidth: 1))
                        .frame(width: 11, height: 11)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityValue("\(done) of \(move.sets) sets done")
    }
}
