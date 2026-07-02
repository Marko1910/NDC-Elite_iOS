import SwiftUI

/// Tab 2 · WOD del atleta — diseño Stitch "WOD Detallado (técnica por ejercicio)".
/// Búsqueda de técnica · héroe (fecha/título/chips) · bloques (calentamiento,
/// fuerza/técnica, metcon) con "ojo" para ver técnica · CTA registrar resultado.
/// (ver FLOWS.md → WodDetailView)
///
/// Datos reales: el próximo WOD publicado (`wods` + `wod_blocks` +
/// `wod_block_exercises`), con los nombres/videos de la Biblioteca Técnica.
struct WodDetailView: View {
    let profile: Profile
    @State private var store = WodDetailStore()

    @State private var search = ""
    @State private var showLogResult = false
    @State private var showHistory = false
    @State private var showLibrary = false
    @State private var techniqueExercise: LibraryExercise?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    searchField
                    LoadStateView(state: store.state, retry: { Task { await store.load() } }) { data in
                        if let data {
                            hero(data)
                            ForEach(data.blocks) { block in
                                WodBlockCard(block: block) { movement in
                                    openTechnique(movement)
                                }
                            }
                            registerCTA
                        } else {
                            ContentUnavailableView(
                                "Sin WOD publicado",
                                systemImage: "calendar.badge.exclamationmark",
                                description: Text("Cuando el coach publique el próximo WOD lo verás aquí.")
                            )
                            .padding(.top, NDCSpacing.stackLG)
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackLG) {
                            SkeletonCard(lines: 2, height: 110)
                            SkeletonCard(lines: 3, height: 160)
                            SkeletonCard(lines: 4, height: 200)
                        }
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $showLogResult) {
                LogWodResultView()
            }
            .navigationDestination(isPresented: $showHistory) {
                WodHistoryView()
            }
            .navigationDestination(isPresented: $showLibrary) {
                ExerciseLibraryView()
            }
            .navigationDestination(item: $techniqueExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NDCBrandLabel()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Historial de WODs")
                }
            }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
        .tint(NDCColor.primary)
    }

    /// El "ojo" abre la técnica del ejercicio en la Biblioteca real.
    private func openTechnique(_ movement: WodDetailStore.Movement) {
        guard let exerciseId = movement.exerciseId,
              let exercise = ExerciseLibraryStore.shared.state.value?.first(where: { $0.id == exerciseId })
        else { return }
        Haptics.impact(.light)
        techniqueExercise = exercise
    }

    // MARK: - Búsqueda de técnica (lleva a la Biblioteca)

    private var searchField: some View {
        HStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(NDCColor.outline)
            TextField("Buscar técnica de movimientos", text: $search)
                .font(NDCFont.bodyMD)
                .submitLabel(.search)
                .onSubmit { showLibrary = true }
            Button("Ir") {
                Haptics.impact(.light)
                showLibrary = true
            }
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.primary)
        }
        .padding(.horizontal, NDCSpacing.gutter)
        .padding(.vertical, 12)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.outline.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Héroe (fecha + título + chips)

    private func hero(_ data: WodDetailStore.Data) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(data.dateLabel.uppercased())
                .font(NDCFont.labelBold)
                .foregroundStyle(NDCColor.outline)
                .tracking(0.5)
            Text(data.wod.title)
                .font(NDCFont.displayLG)
                .foregroundStyle(NDCColor.primaryDark)
            HStack(spacing: NDCSpacing.stackSM) {
                NDCChip(text: data.wod.wodType.displayName)
                if let focus = data.wod.focus {
                    NDCChip(text: focus, color: NDCColor.onSurfaceVariant)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: - CTA registrar resultado

    private var registerCTA: some View {
        Button {
            Haptics.impact()
            showLogResult = true
        } label: {
            Label("Registrar mi Resultado", systemImage: "square.and.pencil")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.secondary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.secondary.opacity(0.25), radius: 8, y: 4)
        }
        .padding(.top, NDCSpacing.stackSM)
        .accessibilityHint("Registra tu tiempo o marca en este WOD")
    }
}

// MARK: - Tarjeta de bloque (calentamiento / fuerza / metcon)

private struct WodBlockCard: View {
    let block: WodDetailStore.Block
    let onTechnique: (WodDetailStore.Movement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            header
            if let scheme = block.scheme {
                Text(scheme)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
            VStack(spacing: 0) {
                ForEach(Array(block.movements.enumerated()), id: \.element.id) { index, mov in
                    MovementRow(movement: mov, showDivider: index < block.movements.count - 1) {
                        onTechnique(mov)
                    }
                }
            }
            if let cue = block.coachCue {
                coachCueBox(cue)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(block.emphasized ? NDCColor.primary : NDCColor.outline.opacity(0.25),
                        lineWidth: block.emphasized ? 2 : 1)
        )
        .shadow(color: NDCColor.primaryDark.opacity(0.08), radius: 12, y: 4)
    }

    private var header: some View {
        HStack(alignment: .top) {
            HStack(spacing: NDCSpacing.stackSM) {
                Image(systemName: block.icon)
                    .foregroundStyle(block.emphasized ? NDCColor.secondary : NDCColor.primary)
                Text(block.title)
                    .font(block.emphasized ? NDCFont.headlineMD : NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
            }
            Spacer()
            if let trailing = block.trailingLabel {
                if block.emphasized {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Tiempo Límite")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.outline)
                        Text(trailing)
                            .font(NDCFont.headlineSM)
                            .foregroundStyle(NDCColor.primary)
                    }
                } else {
                    Text(trailing)
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.outline)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let badge = block.badge {
                Text(badge)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
                    .offset(y: 26)
            }
        }
    }

    private func coachCueBox(_ cue: String) -> some View {
        HStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(NDCColor.secondary)
            Text(cue)
                .font(NDCFont.labelSM)
                .italic()
                .foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .padding(NDCSpacing.stackMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
    }
}

// MARK: - Fila de movimiento (con "ojo" de técnica)

private struct MovementRow: View {
    let movement: WodDetailStore.Movement
    let showDivider: Bool
    let onTechnique: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(movement.name)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.onSurface)
                    if let detail = movement.detail {
                        Text(detail)
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onSurfaceVariant)
                    }
                }
                Spacer()
                if movement.hasTechnique {
                    Button(action: onTechnique) {
                        Image(systemName: "eye")
                            .font(.system(size: 20))
                            .foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Ver técnica de \(movement.name)")
                }
            }
            .padding(.vertical, NDCSpacing.stackMD)
            if showDivider {
                Divider().overlay(NDCColor.outline.opacity(0.25))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Store (WOD publicado real + bloques + ejercicios de la biblioteca)

@MainActor @Observable
final class WodDetailStore {
    struct Movement: Identifiable {
        let id: UUID
        let name: String
        let detail: String?
        let exerciseId: UUID?
        var hasTechnique: Bool { exerciseId != nil }
    }

    struct Block: Identifiable {
        let id: UUID
        let icon: String
        let title: String
        let scheme: String?
        let trailingLabel: String?
        let badge: String?
        let coachCue: String?
        let emphasized: Bool
        let movements: [Movement]
    }

    struct Data {
        let wod: Wod
        let blocks: [Block]

        /// "Hoy, martes 1 de julio" (o la fecha del WOD si no es hoy).
        var dateLabel: String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "es_ES")
            f.dateFormat = "EEEE, d 'de' MMMM"
            let label = f.string(from: wod.scheduledDate)
            return Calendar.current.isDateInToday(wod.scheduledDate) ? "Hoy, \(label)" : label
        }
    }

    /// `.loaded(nil)` = no hay WOD publicado próximo.
    private(set) var state: LoadState<Data?> = .loading
    private let repo = AthleteRepository()

    func load() async {
        state = .loading
        do {
            // La biblioteca da nombre y video a cada ejercicio del WOD.
            await ExerciseLibraryStore.shared.load()
            let library = ExerciseLibraryStore.shared.state.value ?? []
            let namesById = Dictionary(uniqueKeysWithValues: library.map { ($0.id, $0.name) })

            guard let wod = try await repo.nextWod() else {
                state = .loaded(nil)
                return
            }
            let blocks = try await repo.blocks(for: wod.id)
            var blockVMs: [Block] = []
            for block in blocks {
                let rows = try await repo.blockExercises(for: block.id)
                let movements = rows.map { row -> Movement in
                    if let exerciseId = row.exerciseId, let name = namesById[exerciseId] {
                        return Movement(id: row.id, name: name, detail: row.prescription, exerciseId: exerciseId)
                    }
                    return Movement(id: row.id, name: row.prescription, detail: nil, exerciseId: nil)
                }
                blockVMs.append(Self.blockVM(block, wod: wod, movements: movements))
            }
            state = .loaded(Data(wod: wod, blocks: blockVMs))
        } catch {
            state = .failed("No pudimos cargar el WOD. Revisa tu conexión e inténtalo de nuevo.")
        }
    }

    private static func blockVM(_ block: WodBlock, wod: Wod, movements: [Movement]) -> Block {
        let icon: String = switch block.blockType {
        case .calentamiento: "leaf.fill"
        case .fuerza: "dumbbell.fill"
        case .metcon: "timer"
        case .skill: "figure.gymnastics"
        case .accesorio: "plus.circle"
        }
        let emphasized = block.blockType == .metcon
        var trailing: String?
        if let cap = block.timeCapMinutes ?? (emphasized ? wod.timeCapMinutes : nil) {
            trailing = String(format: "%d:00", cap)
        } else if let duration = block.durationMinutes {
            trailing = "\(duration) Minutos"
        }
        return Block(
            id: block.id,
            icon: icon,
            title: block.title ?? block.blockType.displayName,
            scheme: block.rounds.map { "\($0) Rondas de:" },
            trailingLabel: trailing,
            badge: emphasized ? wod.wodType.displayName : nil,
            coachCue: block.notes,
            emphasized: emphasized,
            movements: movements
        )
    }
}

#Preview {
    WodDetailView(profile: .preview)
}
