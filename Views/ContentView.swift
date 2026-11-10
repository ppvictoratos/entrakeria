import SwiftData
import SwiftUI
import UIKit

/// Home: a blank week. Place stops on whatever day life allows, then check off sets.
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \StopLog.day) private var logs: [StopLog]
    @State private var selectedDay = Week.calendar.startOfDay(for: .now)
    @State private var removing: StopLog?
    @State private var showingBack = false
    @State private var showingExtras = false
    @State private var showingTetrad = false

    private var week: [Date] { Week.days(containing: .now) }
    private var isToday: Bool { Week.calendar.isDateInToday(selectedDay) }

    private func logs(on day: Date) -> [StopLog] {
        logs.filter { Week.calendar.isDate($0.day, inSameDayAs: day) }
    }

    private var weekLogs: [StopLog] { logs.filter { log in week.contains { Week.calendar.isDate($0, inSameDayAs: log.day) } } }

    private func isDoneThisWeek(_ stop: WeekStop) -> Bool {
        weekLogs.contains { $0.stopID == stop.id && $0.isStarted }
    }

    private var goalsDone: Int { WeekStop.all.filter { !$0.isBonus && isDoneThisWeek($0) }.count }

    var body: some View {
        ZStack {
            EnkrateiaPalette.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    MeanderBand().frame(height: 18).padding(.top, 8)

                    Text("ΕΝΤΡΑΚΕΡΙΑ")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .kerning(6)
                        .foregroundStyle(EnkrateiaPalette.bronze)

                    WeekStrip(days: week, selectedDay: $selectedDay, logs: logs(on:))

                    tally

                    HStack(spacing: 6) {
                        ForEach(WeekStop.all) { stop in
                            StopChip(stop: stop,
                                     isPlaced: logs(on: selectedDay).contains { $0.stopID == stop.id },
                                     isDone: isDoneThisWeek(stop)) { toggle(stop) }
                        }
                    }

                    dayContent

                    HStack(spacing: 14) {
                        smallLink("ADDITIONAL WORKOUTS") { showingExtras = true }
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(EnkrateiaPalette.clay)
                            .accessibilityHidden(true)
                        smallLink("TETRAD") { showingTetrad = true }
                    }

                    MeanderBand().frame(height: 18).padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            // Solid strip so cards don't scroll under the clock.
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: 0).background(EnkrateiaPalette.bg)
            }
            // Pinned: a sore back shouldn't have to scroll past the workout.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveMyBackButton
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(EnkrateiaPalette.bg)
            }
        }
        .onAppear(perform: updateScreenAwake)
        .onChange(of: selectedDay) { updateScreenAwake() }
        .onChange(of: logs.count) { updateScreenAwake() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            if !week.contains(where: { Week.calendar.isDate($0, inSameDayAs: selectedDay) }) {
                selectedDay = Week.calendar.startOfDay(for: .now)
            }
            updateScreenAwake()
        }
        .confirmationDialog("Clear this stop and its checked sets?",
                            isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }),
                            titleVisibility: .visible) {
            Button("Clear", role: .destructive) {
                if let removing { remove(removing) }
            }
        }
        .sheet(isPresented: $showingBack) {
            SaveMyBackView().presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingExtras) {
            AdditionalWorkoutsView().presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTetrad) {
            TetradView().presentationDragIndicator(.visible)
        }
    }

    private var tally: some View {
        Text("\(goalsDone) / \(WeekStop.goal) THIS WEEK")
            .foregroundStyle(goalsDone >= WeekStop.goal ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)
            .font(.system(size: 11, weight: .medium))
            .kerning(2)
    }

    @ViewBuilder private var dayContent: some View {
        let today = logs(on: selectedDay)
        if today.isEmpty {
            Text(isToday ? "Blank day. Pick a stop, or don't." : "Blank day.")
                .font(.system(size: 14).italic())
                .foregroundStyle(EnkrateiaPalette.bronze)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
        } else {
            ForEach(today) { log in
                if let stop = WeekStop.named(log.stopID) {
                    StopSection(
                        stop: stop,
                        log: log,
                        onDelete: stop.id == "hike" ? { remove(log) } : nil
                    ) { try? context.save() }
                }
            }
        }
    }

    private var saveMyBackButton: some View {
        Button { showingBack = true } label: {
            Label("SAVE MY BACK", systemImage: "cross.case")
                .font(.system(size: 13, weight: .bold))
                .kerning(2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(EnkrateiaPalette.clay)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.clay, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func smallLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .kerning(2)
                .foregroundStyle(EnkrateiaPalette.bronze)
                .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ stop: WeekStop) {
        if stop.id == "hike" {
            // Hike supports multiple entries per day — always add.
            context.insert(StopLog(day: selectedDay, stopID: stop.id))
            try? context.save()
        } else if let placed = logs(on: selectedDay).first(where: { $0.stopID == stop.id }) {
            if placed.isStarted { removing = placed } else { remove(placed) }
        } else {
            context.insert(StopLog(day: selectedDay, stopID: stop.id))
            try? context.save()
        }
    }

    private func remove(_ log: StopLog) {
        context.delete(log)
        try? context.save()
    }

    /// The phone stays awake while today has a workout on screen.
    private func updateScreenAwake() {
        UIApplication.shared.isIdleTimerDisabled = isToday && !logs(on: selectedDay).isEmpty
    }
}

private struct WeekStrip: View {
    let days: [Date]
    @Binding var selectedDay: Date
    let logs: (Date) -> [StopLog]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days, id: \.self) { day in
                let isSelected = Week.calendar.isDate(day, inSameDayAs: selectedDay)
                let isToday = Week.calendar.isDateInToday(day)
                let placed = logs(day)
                Button { selectedDay = Week.calendar.startOfDay(for: day) } label: {
                    VStack(spacing: 6) {
                        Text(day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(isToday ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? EnkrateiaPalette.gold : EnkrateiaPalette.line,
                                        lineWidth: isSelected ? 1.5 : 1)
                            if let first = placed.first, let stop = WeekStop.named(first.stopID) {
                                StopIcon(symbol: stop.symbol, size: 16)
                                    .foregroundStyle(first.isStarted ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)
                            }
                            if placed.count > 1 {
                                Text("+\(placed.count - 1)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(EnkrateiaPalette.bronze)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                    .padding(3)
                            }
                        }
                        .frame(height: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct StopChip: View {
    let stop: WeekStop
    let isPlaced: Bool
    let isDone: Bool
    let action: () -> Void

    private var tint: Color { isPlaced || isDone ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                StopIcon(symbol: isDone ? "checkmark" : stop.symbol, size: 18)
                    .frame(height: 22)
                Text(stop.name.uppercased())
                    .font(.system(size: 8, weight: .semibold))
                    .kerning(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(RoundedRectangle(cornerRadius: 6)
                .fill(isPlaced ? EnkrateiaPalette.clay.opacity(0.18) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .stroke(isPlaced ? EnkrateiaPalette.gold : EnkrateiaPalette.line, lineWidth: isPlaced ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(stop.name)
        .accessibilityValue(isDone ? "Done this week" : isPlaced ? "On this day" : "")
    }
}

private struct StopSection: View {
    let stop: WeekStop
    @Bindable var log: StopLog
    var onDelete: (() -> Void)? = nil
    let onChange: () -> Void

    @State private var placeDraft = ""
    @State private var importMessage: String?
    @State private var isImporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(stop.name.uppercased())
                    .font(.system(size: 12, weight: .semibold))
                    .kerning(2)
                    .foregroundStyle(EnkrateiaPalette.gold)
                Spacer()
                Text(stop.tagline)
                    .font(.system(size: 11).italic())
                    .foregroundStyle(EnkrateiaPalette.bronze)
                if let onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(EnkrateiaPalette.bronze)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 8)
                }
            }
            ForEach(stop.moves) { move in
                MoveCard(move: move, done: log.setCounts[move.name] ?? 0) { count in
                    log.setCounts[move.name] = count
                    onChange()
                }
            }
            if stop.id == "hike" { hikePlace }
            statsLog
        }
        .onAppear { placeDraft = log.placeName ?? "" }
        .onChange(of: log.notes) { onChange() }
    }

    private var hikePlace: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Where did you go?", text: $placeDraft)
                .font(.system(size: 15))
                .foregroundStyle(EnkrateiaPalette.parchment)
                .submitLabel(.search)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.line, lineWidth: 1))
                .onSubmit(findPlace)

            // Rating
            HStack {
                Text("RATING")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(2)
                    .foregroundStyle(EnkrateiaPalette.bronze)
                Spacer()
                Text(log.rating == 0 ? "—" : "\(log.rating) / 10")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(log.rating > 0 ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze)
                Stepper("", value: $log.rating, in: 0...10)
                    .labelsHidden()
                    .onChange(of: log.rating) { onChange() }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.line, lineWidth: 1))

            // Dog
            Toggle(isOn: $log.dogCame) {
                Label("DOG CAME", systemImage: "dog.fill")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(2)
                    .foregroundStyle(EnkrateiaPalette.bronze)
            }
            .tint(EnkrateiaPalette.gold)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.line, lineWidth: 1))
            .onChange(of: log.dogCame) { onChange() }

            if let name = log.placeName, let lat = log.latitude, let lon = log.longitude {
                TopoMapView(place: name, latitude: lat, longitude: lon)
            }
        }
    }

    private var statsLog: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Log your stats", text: $log.notes, axis: .vertical)
                .font(.system(size: 14))
                .foregroundStyle(EnkrateiaPalette.parchment)
                .lineLimit(2...8)
                .padding(12)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.line, lineWidth: 1))

            Button(action: importFromHealth) {
                Label(isImporting ? "CHECKING HEALTH…" : "IMPORT FROM APPLE HEALTH", systemImage: "heart")
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .disabled(isImporting)

            if let importMessage {
                Text(importMessage)
                    .font(.system(size: 12).italic())
                    .foregroundStyle(EnkrateiaPalette.bronze)
            }
        }
    }

    private func findPlace() {
        let place = placeDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !place.isEmpty else { return }
        log.placeName = place
        Task {
            if let found = try? await TopoMap.coordinate(for: place) {
                log.latitude = found.latitude
                log.longitude = found.longitude
            } else {
                log.latitude = nil
                log.longitude = nil
            }
            onChange()
        }
    }

    private func importFromHealth() {
        isImporting = true
        importMessage = nil
        Task {
            defer { isImporting = false }
            do {
                guard let summary = try await HealthImporter.summary(for: stop, on: log.day) else {
                    importMessage = "No \(stop.name.lowercased()) workout in Health for this day."
                    return
                }
                if !log.notes.contains(summary) {
                    log.notes = log.notes.isEmpty ? summary : log.notes + "\n" + summary
                }
            } catch {
                importMessage = "Couldn't read from Apple Health."
            }
        }
    }
}

private struct MoveCard: View {
    let move: Move
    let done: Int
    let setDone: (Int) -> Void

    private var finished: Bool { done >= move.sets }

    var body: some View {
        HStack(spacing: 12) {
            StopIcon(symbol: move.symbol, size: 26, weight: .ultraLight)
                .foregroundStyle(finished ? EnkrateiaPalette.gold : EnkrateiaPalette.clay)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(move.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(EnkrateiaPalette.parchment)
                Text(move.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(EnkrateiaPalette.bronze)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 0) {
                    ForEach(0..<move.sets, id: \.self) { i in
                        Button {
                            // Tapping the last filled dot steps back, so a mistap is one tap to undo.
                            setDone(done == i + 1 ? i : i + 1)
                        } label: {
                            Circle()
                                .fill(i < done ? EnkrateiaPalette.gold : .clear)
                                .overlay(Circle().stroke(i < done ? EnkrateiaPalette.gold : EnkrateiaPalette.bronze, lineWidth: 1))
                                .frame(width: 22, height: 22)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(move.name), set \(i + 1) of \(move.sets)")
                        .accessibilityValue(i < done ? "Done" : "Not done")
                    }
                }
                .padding(.leading, -11)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 2)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(finished ? EnkrateiaPalette.bronze : EnkrateiaPalette.line, lineWidth: 1))
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StopLog.self, BackCheck.self], inMemory: true)
}
