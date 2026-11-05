import SwiftUI

/// The back-care list: everything outside the tetrad, kept handy.
struct AdditionalWorkoutsView: View {
    var body: some View {
        ZStack {
            EnkrateiaPalette.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ADDITIONAL WORKOUTS")
                            .font(.system(size: 15, weight: .semibold, design: .serif))
                            .kerning(4)
                            .foregroundStyle(EnkrateiaPalette.gold)
                        Text("BACK CARE")
                            .font(.system(size: 10, weight: .medium))
                            .kerning(2)
                            .foregroundStyle(EnkrateiaPalette.bronze)
                    }

                    ForEach(rehabSections) { section in
                        SectionBlock(section: section)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private struct SectionBlock: View {
    let section: RehabSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .kerning(2)
                .foregroundStyle(section.urgent ? EnkrateiaPalette.clay : EnkrateiaPalette.gold)

            if let note = section.note {
                Text(note)
                    .font(.system(size: 12).italic())
                    .foregroundStyle(EnkrateiaPalette.bronze)
            }

            VStack(alignment: .leading, spacing: 7) {
                ForEach(section.items) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Rectangle()
                            .fill(EnkrateiaPalette.line)
                            .frame(width: 5, height: 5)
                            .rotationEffect(.degrees(45))
                        Text(item.text)
                            .font(.system(size: 14))
                            .foregroundStyle(EnkrateiaPalette.parchment)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(section.urgent ? EnkrateiaPalette.clay : EnkrateiaPalette.line, lineWidth: 1))
    }
}

// MARK: - Content

struct RehabItem: Identifiable {
    let id = UUID()
    let text: String
}

struct RehabSection: Identifiable {
    let id = UUID()
    let title: String
    var note: String? = nil
    var urgent = false
    let items: [RehabItem]

    init(_ title: String, note: String? = nil, urgent: Bool = false, _ items: [String]) {
        self.title = title; self.note = note; self.urgent = urgent
        self.items = items.map { RehabItem(text: $0) }
    }
}

let rehabSections: [RehabSection] = [
    .init("Daily non-negotiables", [
        "McGill Big 3: curl-up, side plank (each side), bird-dog — 2–3 sets each, 5–10 min total",
        "A walk outside",
        "Dead hang from pull-up bar — 30–60 sec (decompression)"
    ]),
    .init("Quick reset", note: "Pick one.", [
        "Glute bridges",
        "Pigeons",
        "Clamshells"
    ]),
    .init("Floor reset", [
        "Pelvic tilts — 29 slow reps, flat back",
        "Glute bridges — 2×12, 2 sec squeeze",
        "Ham bridges — 2×12, 2 sec squeeze",
        "Clamshells — 2×20 each side",
        "Lateral leg lifts — 2×10",
        "Child's pose — 60 sec",
        "Cat-cows — 3×10",
        "Pigeon — 60 sec each side",
        "90/90 hip stretch — 60 sec each side",
        "Dead bug — 3×8 each side (opposite arm/leg, slow)",
        "Curl-up L/R — 2×10 each",
        "Single-leg RDLs",
        "Hamstring walkouts",
        "Flexed arm hang — 1 min"
    ]),
    .init("Movement + meditation anchor",
          note: "Use when: body tension, couch trap, sciatic flare.", [
        "15 min reset — shake, cat-cow, down dog, lunges, shoulder rolls, twist",
        "7 min breath work — 4 in, 6 out"
    ]),
    .init("Pre-workout warm-up · 5 min", [
        "Cat-cow — 10 reps",
        "Hip flexor stretch — 30 sec/side",
        "Glute bridge — 15 reps",
        "Bird-dog — 5/side",
        "Bodyweight squat to depth — 10 reps"
    ]),
    .init("Home lower (hinge)", [
        "Goblet squat, 12 lb KB — 4×8, slow tempo",
        "KB RDL, 12 lb — 4×8, deliberate hinge, neutral spine",
        "Reverse lunges down hallway, 15 lb DBs — 3×10/leg",
        "Single-leg RDL, 15 lb DB — 3×8/leg",
        "Suitcase farmer carry, 12 lb KB — 4 rounds hallway down-and-back, switch hands",
        "Single-leg glute bridge — 3×12/leg",
        "Side plank — 3×30 sec/side"
    ]),
    .init("Home upper", [
        "Pull-ups — 4 × AMRAP (stop 1–2 short of failure)",
        "Push-ups — 4 × AMRAP",
        "KB single-arm row, 12 lb — 4×10/arm",
        "KB overhead press, 12 lb — 3×8/arm",
        "Half-kneeling Pallof press, 12 lb KB at chest — 3×10/side, resist rotation",
        "Dead hang — 3×30 sec"
    ]),
    .init("Hard rules", [
        "Neutral spine under load. Always.",
        "Hinge from the hips, not the low back.",
        "Brace 360° before every rep.",
        "No loaded spinal flexion: skip sit-ups, crunches, weighted twists, Jefferson curls, toes-to-bar.",
        "No loaded spinal rotation. Anti-rotation only (Pallof, carries).",
        "No barbell back squats or conventional deadlifts for now.",
        "KB swings and Turkish get-ups: hold off until symptoms are calm and hinge is bulletproof.",
        "If something sends sciatica down the leg, stop that movement."
    ]),
    .init("Progression", [
        "Add reps before weight. Top of the rep range with clean form for 2 sessions → add load or reps next time.",
        "12 lb KB is home base for safety. When it gets easy, add reps first, then move up to the 25 lb KB or the gym for heavier hinge work.",
        "Reassess every 4–6 weeks. Symptoms improving and form solid → expand exercise selection."
    ]),
    .init("Watch for", urgent: true, [
        "Numbness or weakness getting worse, not better",
        "Foot drop, leg buckling",
        "Any saddle-area numbness or bladder/bowel changes → ER, not the gym"
    ])
]

#Preview {
    AdditionalWorkoutsView()
}
