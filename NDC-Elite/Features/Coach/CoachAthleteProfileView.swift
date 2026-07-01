import SwiftUI

/// Perfil de Atleta - Vista Coach — diseño Stitch "Perfil de Atleta - Vista Coach".
/// El coach ve el perfil completo de un atleta: estado, lesión, WOD de hoy, PRs,
/// historial de WODs y notas del coach (puede añadir nota). Se llega desde
/// Gestión de Atletas ("Ver Perfil"). (ver FLOWS.md → CoachAthleteProfileView)
///
/// TODO(datos): hoy usa `CoachAthleteData.sample`. Conectar a Supabase:
/// profiles, injuries, wod_results, personal_records, coach_notes.
struct CoachAthleteProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let athleteName: String
    private typealias data = CoachAthleteData
    @State private var showAddNote = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                header
                if let injury = data.injury { injuryCard(injury) }
                todayWodCard
                prsSection
                wodHistorySection
                coachNotesSection
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Perfil de Atleta")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddNote) { AddNoteView(athleteName: athleteName) }
    }

    private var header: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: nil, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(athleteName).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                HStack(spacing: NDCSpacing.stackSM) {
                    NDCChip(text: data.level)
                    Text(data.compliance).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
            }
            Spacer()
        }
    }

    private func injuryCard(_ injury: CoachAthleteData.Injury) -> some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: "cross.case.fill").foregroundStyle(NDCColor.error)
            VStack(alignment: .leading, spacing: 2) {
                Text(injury.title).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("Severidad: \(injury.severity)").font(NDCFont.labelSM).foregroundStyle(NDCColor.error)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.error.opacity(0.08), in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.error.opacity(0.3), lineWidth: 1))
    }

    private var todayWodCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WOD DE HOY").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
                Text(data.todayWod).font(NDCFont.headlineSM).foregroundStyle(.white)
                Text("Nivel: \(data.level)").font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(data.todayResult).font(NDCFont.headlineMD).foregroundStyle(NDCColor.accent)
                Label("PR!", systemImage: "star.fill").font(NDCFont.labelSM).foregroundStyle(NDCColor.accent)
            }
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
    }

    private var prsSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("PRs Personales").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Label("Ver todos", systemImage: "chevron.right.2").font(NDCFont.labelSM).foregroundStyle(NDCColor.primary)
            }
            HStack(spacing: NDCSpacing.gutter) {
                ForEach(data.prs) { pr in
                    VStack(spacing: 4) {
                        Text(pr.value).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                        Text(pr.name).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NDCSpacing.gutter)
                    .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                }
            }
        }
    }

    private var wodHistorySection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Historial de WODs").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            ForEach(data.history) { h in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(h.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                        Text("\(h.date) • \(h.result)").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    Spacer()
                    NDCChip(text: h.level)
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
            }
        }
    }

    private var coachNotesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Label("Coach Notes", systemImage: "square.and.pencil").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Button {
                    Haptics.impact()
                    showAddNote = true
                } label: {
                    Image(systemName: "plus.circle.fill").foregroundStyle(NDCColor.primary)
                }
                .accessibilityLabel("Añadir nota")
            }
            Text("\"\(data.coachNote)\"")
                .font(NDCFont.bodyMD).italic().foregroundStyle(NDCColor.onSurfaceVariant)
                .padding(NDCSpacing.stackLG)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }
}

private enum CoachAthleteData {
    struct Injury { let title, severity: String }
    struct PR: Identifiable { let id = UUID(); let name, value: String }
    struct History: Identifiable { let id = UUID(); let name, date, result, level: String }

    static let level = "Avanzado RX"
    static let compliance = "85% Compliance"
    static let injury: Injury? = Injury(title: "Sobrecarga en lumbar", severity: "Moderada")
    static let todayWod = "Fran"
    static let todayResult = "03:45 min"
    static let prs: [PR] = [.init(name: "Back Squat", value: "145 kg"), .init(name: "Clean", value: "110 kg"), .init(name: "Snatch", value: "85 kg")]
    static let history: [History] = [
        .init(name: "The Ghost", date: "12 Oct", result: "142 reps", level: "RX"),
        .init(name: "Murph", date: "08 Oct", result: "38:22 min", level: "Escalado"),
        .init(name: "Havana", date: "05 Oct", result: "15 rondas", level: "RX")
    ]
    static let coachNote = "Mariana está mostrando una técnica excepcional en el snatch, pero debemos cuidar la progresión del peso muerto debido a la molestia lumbar reportada el lunes."
}

#Preview {
    NavigationStack { CoachAthleteProfileView(athleteName: "Mariana Ortiz") }
}
