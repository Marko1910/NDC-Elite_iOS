import SwiftUI

/// Perfil de Atleta - Vista Coach — diseño Stitch "Perfil de Atleta - Vista Coach".
/// El coach ve el perfil completo de un atleta: estado, lesión, WOD de hoy, PRs,
/// historial de WODs y notas del coach (puede añadir nota). Se llega desde
/// Gestión de Atletas ("Ver Perfil"). (ver FLOWS.md → CoachAthleteProfileView)
///
/// TODO(datos): usa `CoachAthleteData.sample` para las secciones internas.
/// Conectar a Supabase: injuries, wod_results, personal_records, coach_notes.
/// El atleta (`profiles`) ya llega real desde Gestión de Atletas.
struct CoachAthleteProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let athlete: Profile
    private typealias data = CoachAthleteData
    @State private var showAddNote = false
    @State private var prStore = CoachAthletePrsStore()

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
        .sheet(isPresented: $showAddNote) { AddNoteView(athlete: athlete) }
        .task { await prStore.load(athleteId: athlete.id) }
        .refreshable { await prStore.load(athleteId: athlete.id) }
    }

    private var header: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.fullName).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                HStack(spacing: NDCSpacing.stackSM) {
                    NDCChip(text: athlete.level.displayName)
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

    /// PRs reales del atleta: la última marca de CADA ejercicio que registró.
    private var prsSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("PRs Personales").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            LoadStateView(
                state: prStore.state,
                retry: { Task { await prStore.load(athleteId: athlete.id) } }
            ) { marks in
                if marks.isEmpty {
                    Text("Este atleta aún no registra marcas.")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                } else {
                    ForEach(marks) { mark in
                        HStack(spacing: NDCSpacing.gutter) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mark.exerciseName)
                                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                                Text("\(mark.recordCount) marca\(mark.recordCount == 1 ? "" : "s") · \(mark.dateLabel)")
                                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(mark.valueLabel)
                                    .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                                Text(mark.status.rawValue.uppercased())
                                    .font(NDCFont.labelSM)
                                    .foregroundStyle(mark.status == .validado ? .green : NDCColor.onAccent)
                            }
                        }
                        .padding(NDCSpacing.gutter)
                        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                        .accessibilityElement(children: .combine)
                    }
                }
            } skeleton: {
                VStack(spacing: NDCSpacing.stackSM) {
                    SkeletonCard(lines: 1, height: 64)
                    SkeletonCard(lines: 1, height: 64)
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

// MARK: - Store (última marca real de cada ejercicio del atleta)

@MainActor @Observable
final class CoachAthletePrsStore {
    struct Mark: Identifiable {
        let id: UUID
        let exerciseName: String
        let valueLabel: String
        let dateLabel: String
        let recordCount: Int
        let status: ResultStatus
    }

    private(set) var state: LoadState<[Mark]> = .loading
    private let repo = AthleteRepository()

    func load(athleteId: UUID) async {
        state = .loading
        do {
            let records = try await repo.personalRecords(athleteId: athleteId)
            guard !records.isEmpty else { state = .loaded([]); return }
            let exercises = try await repo.exercises(ids: Array(Set(records.map(\.exerciseId))))
            let namesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.nameEs ?? $0.name) })

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.dateFormat = "d MMM"

            let grouped = Dictionary(grouping: records, by: \.exerciseId)
            let marks: [(Date, Mark)] = grouped.compactMap { exerciseId, recs in
                guard let latest = recs.max(by: { $0.recordDate < $1.recordDate }) else { return nil }
                let mark = Mark(
                    id: latest.id,
                    exerciseName: namesById[exerciseId] ?? "Ejercicio",
                    valueLabel: latest.scoreType.format(latest.value),
                    dateLabel: Calendar.current.isDateInToday(latest.recordDate)
                        ? "Hoy" : formatter.string(from: latest.recordDate),
                    recordCount: recs.count,
                    status: latest.status
                )
                return (latest.recordDate, mark)
            }
            state = .loaded(marks.sorted { $0.0 > $1.0 }.map(\.1))
        } catch {
            state = .failed("No se pudieron cargar los PRs del atleta.")
        }
    }
}

private enum CoachAthleteData {
    struct Injury { let title, severity: String }
    struct History: Identifiable { let id = UUID(); let name, date, result, level: String }

    static let level = "Avanzado"
    static let compliance = "85% Asistencia"
    static let injury: Injury? = Injury(title: "Sobrecarga en lumbar", severity: "Moderada")
    static let todayWod = "Fran"
    static let todayResult = "03:45 min"
    static let history: [History] = [
        .init(name: "The Ghost", date: "12 Oct", result: "142 reps", level: "Avanzado"),
        .init(name: "Murph", date: "08 Oct", result: "38:22 min", level: "Intermedio"),
        .init(name: "Havana", date: "05 Oct", result: "15 rondas", level: "Avanzado")
    ]
    static let coachNote = "Mariana está mostrando una técnica excepcional en el snatch, pero debemos cuidar la progresión del peso muerto debido a la molestia lumbar reportada el lunes."
}

#Preview {
    NavigationStack { CoachAthleteProfileView(athlete: .preview) }
}
