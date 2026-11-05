import SwiftData
import SwiftUI

/// The short reset for a sore back. Checks clear themselves each day.
struct SaveMyBackView: View {
    @Environment(\.modelContext) private var context
    @Query private var checks: [BackCheck]

    private var todayChecks: [BackCheck] {
        checks.filter { Week.calendar.isDateInToday($0.day) }
    }

    var body: some View {
        ZStack {
            EnkrateiaPalette.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("SAVE MY BACK")
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .kerning(4)
                            .foregroundStyle(EnkrateiaPalette.gold)
                        Text("Do what today calls for. All of it is optional.")
                            .font(.system(size: 12).italic())
                            .foregroundStyle(EnkrateiaPalette.bronze)
                    }

                    group("MOVE", SaveMyBack.move)
                    group("REST", SaveMyBack.rest)

                    Text("Sciatica shooting down the leg: stop that movement. Saddle numbness or bladder/bowel changes: ER, not the gym.")
                        .font(.system(size: 12))
                        .foregroundStyle(EnkrateiaPalette.clay)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(EnkrateiaPalette.clay, lineWidth: 1))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
    }

    private func group(_ title: String, _ items: [BackItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .kerning(2)
                .foregroundStyle(EnkrateiaPalette.bronze)
            ForEach(items) { row($0) }
        }
    }

    private func row(_ item: BackItem) -> some View {
        let done = todayChecks.contains { $0.itemID == item.id }
        return Button { toggle(item) } label: {
            HStack(spacing: 12) {
                Image(systemName: done ? "checkmark" : item.symbol)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(done ? EnkrateiaPalette.gold : EnkrateiaPalette.clay)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(EnkrateiaPalette.parchment)
                    Text(item.detail)
                        .font(.system(size: 12))
                        .foregroundStyle(EnkrateiaPalette.bronze)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .contentShape(Rectangle())
            .overlay(RoundedRectangle(cornerRadius: 8)
                .stroke(done ? EnkrateiaPalette.gold : EnkrateiaPalette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityValue(done ? "Done today" : "")
    }

    private func toggle(_ item: BackItem) {
        if let existing = todayChecks.first(where: { $0.itemID == item.id }) {
            context.delete(existing)
        } else {
            context.insert(BackCheck(day: .now, itemID: item.id))
        }
        try? context.save()
    }
}
