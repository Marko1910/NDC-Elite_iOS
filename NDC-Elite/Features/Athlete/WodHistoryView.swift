import SwiftUI

/// Historial de WODs del atleta — pantalla nueva (no existe en Stitch; diseñada
/// coherente con el design system NDC HQ). Lista los WODs pasados con el
/// resultado registrado por el atleta y su estado de validación. Se accede
/// desde el icono de historial del tab WOD.
///
/// Datos reales: `wods` pasados publicados + `wod_results` del atleta
/// (tiempo/rounds/reps/peso, status, is_pr).
struct WodHistoryView: View {
    let profile: Profile
    @State private var store = WodHistoryStore()
    @State private var filter: Filter = .todos
    @State private var selectedEntry: WodHistoryStore.Entry?

    enum Filter: String, CaseIterable { case todos = "Todos", registrados = "Registrados", pendientes = "Pendientes" }

    private func filtered(_ entries: [WodHistoryStore.Entry]) -> [WodHistoryStore.Entry] {
        switch filter {
        case .todos: entries
        case .registrados: entries.filter { $0.result != nil }
        case .pendientes: entries.filter { $0.result == nil }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                LoadStateView(state: store.state, retry: { Task { await store.load(athleteId: profile.id) } }) { data in
                    let visible = filtered(data.entries)
                    VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                        summaryCard(data)
                        filterChips
                        if visible.isEmpty {
                            ContentUnavailableView("Sin WODs", systemImage: "calendar.badge.exclamationmark",
                                                   description: Text("No hay entrenamientos en esta categoría."))
                                .padding(.top, NDCSpacing.stackLG)
                        } else {
                            ForEach(visible) { entry in
                                Button {
                                    Haptics.impact(.light)
                                    selectedEntry = entry
                                } label: {
                                    WodHistoryRow(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackMD) {
                        SkeletonCard(lines: 1, height: 90)
                        SkeletonCard(lines: 2, height: 80)
                        SkeletonCard(lines: 2, height: 80)
                        SkeletonCard(lines: 2, height: 80)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Historial de WODs")
        .navigationBarTitleDisplayMode(.large)
        .task { await store.load(athleteId: profile.id) }
        .refreshable { await store.load(athleteId: profile.id) }
        .sheet(item: $selectedEntry) { entry in
            WodExercisesSheet(wodId: entry.id, title: entry.title)
        }
    }

    // MARK: - Resumen

    private func summaryCard(_ data: WodHistoryStore.Data) -> some View {
        HStack(spacing: NDCSpacing.gutter) {
            summaryStat(value: "\(data.totalCompleted)", label: "Completados")
            Divider().frame(height: 40).overlay(.white.opacity(0.2))
            summaryStat(value: "\(data.prCount)", label: "PRs")
            Divider().frame(height: 40).overlay(.white.opacity(0.2))
            summaryStat(value: data.compliance, label: "Cumplimiento")
        }
        .frame(maxWidth: .infinity)
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.totalCompleted) WODs completados, \(data.prCount) PRs, cumplimiento \(data.compliance)")
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(NDCFont.headlineMD).foregroundStyle(.white)
            Text(label).font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filtro

    private var filterChips: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            ForEach(Filter.allCases, id: \.self) { f in
                Button {
                    Haptics.selection()
                    withAnimation(.snappy) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(filter == f ? .white : NDCColor.primary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(filter == f ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
                }
                .accessibilityAddTraits(filter == f ? .isSelected : [])
            }
            Spacer()
        }
    }
}

// MARK: - Fila del historial

private struct WodHistoryRow: View {
    let entry: WodHistoryStore.Entry

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            // Fecha (día + mes)
            VStack(spacing: 0) {
                Text(entry.day).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                Text(entry.month.uppercased()).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            .frame(width: 48)

            Rectangle().fill(NDCColor.outline.opacity(0.2)).frame(width: 1, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: NDCSpacing.stackSM) {
                    NDCChip(text: entry.type)
                    if entry.isPr {
                        Label("PR", systemImage: "star.fill")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onAccent)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(NDCColor.accent, in: .capsule)
                    }
                }
                Text(entry.title).font(NDCFont.bodyLG.weight(.semibold)).foregroundStyle(NDCColor.onSurface)
                if let result = entry.result {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(entry.validated ? .green : NDCColor.outline)
                        Text(result).font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        Text(entry.validated ? "· Validado" : "· Pendiente")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                } else {
                    Text("Sin resultado registrado")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large)
            .stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
    }

    private var a11yLabel: String {
        var s = "\(entry.day) de \(entry.month), \(entry.title), \(entry.type)"
        if let r = entry.result { s += ", resultado \(r), \(entry.validated ? "validado" : "pendiente")" }
        else { s += ", sin resultado" }
        if entry.isPr { s += ", récord personal" }
        return s
    }
}

// MARK: - Store (WODs pasados + resultados reales del atleta)

@MainActor @Observable
final class WodHistoryStore {
    struct Data {
        let totalCompleted: Int
        let prCount: Int
        /// % de WODs pasados con resultado registrado.
        let compliance: String
        let entries: [Entry]
    }

    struct Entry: Identifiable {
        let id: UUID
        let day: String
        let month: String
        let title: String
        let type: String
        let result: String?
        let validated: Bool
        let isPr: Bool
    }

    private(set) var state: LoadState<Data> = .loading
    private let repo = AthleteRepository()

    private static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "d"; return f
    }()
    private static let monthFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "MMM"; return f
    }()

    func load(athleteId: UUID) async {
        if state.value == nil { state = .loading }
        do {
            let wods = try await repo.pastWods()
            let results = try await repo.wodResults(athleteId: athleteId)
            let resultByWod = Dictionary(grouping: results, by: \.wodId).compactMapValues(\.first)

            let entries = wods.map { wod -> Entry in
                let result = resultByWod[wod.id]
                return Entry(
                    id: wod.id,
                    day: Self.dayFmt.string(from: wod.scheduledDate),
                    month: Self.monthFmt.string(from: wod.scheduledDate).replacingOccurrences(of: ".", with: ""),
                    title: wod.title,
                    type: wod.wodType.displayName.uppercased(),
                    result: result.map(Self.format),
                    validated: result?.status == .validado,
                    isPr: result?.isPr ?? false
                )
            }
            let completed = entries.filter { $0.result != nil }.count
            let compliance = entries.isEmpty ? "—" : "\(completed * 100 / entries.count)%"
            state = .loaded(Data(
                totalCompleted: completed,
                prCount: entries.filter(\.isPr).count,
                compliance: compliance,
                entries: entries
            ))
        } catch {
            state = .failed("No se pudo cargar el historial.")
        }
    }

    /// Resultado legible según lo que registró el atleta: tiempo (mm:ss),
    /// rounds + reps (AMRAP), solo reps, o peso.
    private static func format(_ result: WodResult) -> String {
        if let secs = result.timeSeconds {
            return String(format: "%d:%02d", secs / 60, secs % 60)
        }
        if let rounds = result.rounds {
            let reps = result.reps.map { " + \($0)" } ?? ""
            return "\(rounds) rondas\(reps)"
        }
        if let reps = result.reps { return "\(reps) reps" }
        if let kg = result.weightUsedKg { return "\(kg.formatted()) kg" }
        return "Registrado"
    }
}

#Preview {
    NavigationStack { WodHistoryView(profile: .preview) }
}
