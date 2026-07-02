import SwiftUI

/// Tab 3 · Progreso del atleta — diseño Stitch "Rendimiento y Ranking Unificado".
/// Sirve para revisar los PR por ejercicio y la progresión general.
/// Header del atleta · hero de rendimiento · Recientes (último logro) ·
/// Marcas Clave (PR por ejercicio) · FAB registrar PR.
/// (ver FLOWS.md → PerformanceView)
///
/// Datos reales: `personal_records` del atleta (hero, último logro y la marca
/// más reciente de cada ejercicio), con nombres de `exercises`.
struct PerformanceView: View {
    let profile: Profile
    @State private var store = PerformanceStore()

    @State private var showLogPr = false
    @State private var showPrDetail = false
    @State private var showLibrary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    athleteHeader
                    Text("Rendimiento y Ranking")
                        .font(NDCFont.displayLG)
                        .foregroundStyle(NDCColor.primaryDark)
                    LoadStateView(state: store.state, retry: { Task { await store.load(athleteId: profile.id) } }) { data in
                        if data.hero.totalPRs == 0 {
                            ContentUnavailableView(
                                "Aún sin marcas",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Registra tu primer PR con el botón + para ver tu progreso aquí.")
                            )
                            .padding(.top, NDCSpacing.stackLG)
                        } else {
                            PerformanceHeroCard(hero: data.hero)
                            if let recent = data.recent {
                                recientesSection(recent)
                            }
                            marcasClaveSection(data.keyMarks)
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackLG) {
                            SkeletonCard(lines: 3, height: 150)
                            SkeletonCard(lines: 2, height: 90)
                            SkeletonCard(lines: 2, height: 90)
                        }
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, 96) // espacio para el FAB
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottomTrailing) { logPrFAB }
            .sheet(isPresented: $showLogPr) { LogPrSheet() }
            .navigationDestination(isPresented: $showPrDetail) {
                PrDetailView(profile: profile)
            }
            .navigationDestination(isPresented: $showLibrary) {
                ExerciseLibraryView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await store.load(athleteId: profile.id) }
            .refreshable { await store.load(athleteId: profile.id) }
            .onChange(of: showLogPr) { _, isShowing in
                // Al cerrar el registro de PR, refresca las marcas.
                if !isShowing { Task { await store.load(athleteId: profile.id) } }
            }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Header del atleta (avatar + nombre · biblioteca)

    private var athleteHeader: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            NDCAvatarView(urlString: profile.avatarURL, size: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(profile.fullName)
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
                Text("Nivel \(profile.level.displayName)")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.onSurfaceVariant)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                Haptics.impact(.light)
                showLibrary = true
            } label: {
                Image(systemName: "books.vertical")
                    .font(.system(size: 20))
                    .foregroundStyle(NDCColor.primary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Biblioteca de técnica")
        }
    }

    // MARK: - Recientes (último logro real)

    private func recientesSection(_ recent: PerformanceStore.Data.Recent) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Recientes")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
            Button {
                Haptics.impact(.light)
                showPrDetail = true
            } label: {
                HStack(spacing: NDCSpacing.gutter) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(NDCColor.secondary)
                        .frame(width: 56, height: 56)
                        .background(NDCColor.accent.opacity(0.20), in: .rect(cornerRadius: NDCRadius.standard))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ÚLTIMO LOGRO")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onSurfaceVariant)
                        Text(recent.exercise)
                            .font(NDCFont.headlineSM)
                            .foregroundStyle(NDCColor.primary)
                        HStack(spacing: 4) {
                            Text(recent.value)
                                .font(NDCFont.bodyLG.weight(.bold))
                                .foregroundStyle(NDCColor.primary)
                            if let delta = recent.delta {
                                Text(delta)
                                    .font(NDCFont.bodyMD)
                                    .foregroundStyle(NDCColor.error)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: NDCRadius.large)
                        .stroke(NDCColor.outline.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: NDCColor.primaryDark.opacity(0.06), radius: 6, y: 2)
            }
            .accessibilityLabel("Último logro: \(recent.exercise), \(recent.value)")
        }
    }

    // MARK: - Marcas Clave (última marca real de cada ejercicio)

    private func marcasClaveSection(_ marks: [PerformanceStore.Data.KeyMark]) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Marcas Clave")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
            VStack(spacing: NDCSpacing.stackMD) {
                ForEach(marks) { mark in
                    KeyMarkRow(mark: mark) {
                        Haptics.impact(.light)
                        showPrDetail = true
                    }
                }
            }
        }
    }

    // MARK: - FAB registrar PR

    private var logPrFAB: some View {
        Button {
            Haptics.impact()
            showLogPr = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(NDCColor.primary)
                .frame(width: 56, height: 56)
                .background(NDCColor.accent, in: .circle)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.trailing, NDCSpacing.marginMain)
        .padding(.bottom, NDCSpacing.stackLG)
        .accessibilityLabel("Registrar nueva marca")
    }
}

// MARK: - Hero "Estado de Rendimiento"

private struct PerformanceHeroCard: View {
    let hero: PerformanceStore.Data.Hero

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(alignment: .top) {
                Text("ESTADO DE RENDIMIENTO")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1)
                Spacer()
                Label("ACTIVO", systemImage: "bolt.fill")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Rendimiento Total")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(.white.opacity(0.9))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(hero.totalPRs) PRs")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(.white)
                    Text(hero.deltaLabel)
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.accent)
                }
                Text("marcas registradas · \(hero.validatedCount) validadas por el coach")
                    .font(NDCFont.bodyMD)
                    .foregroundStyle(.white.opacity(0.7))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.20))
                    Capsule().fill(NDCColor.accent)
                        .frame(width: geo.size.width * hero.progress)
                }
            }
            .frame(height: 4)
            .padding(.top, NDCSpacing.stackSM)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estado de rendimiento, activo. \(hero.totalPRs) PRs, \(hero.deltaLabel)")
    }
}

// MARK: - Fila de PR por ejercicio

private struct KeyMarkRow: View {
    let mark: PerformanceStore.Data.KeyMark
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: NDCSpacing.stackMD) {
                    Image(systemName: mark.icon)
                        .foregroundStyle(NDCColor.primary)
                    Text(mark.name)
                        .font(NDCFont.bodyLG.weight(.semibold))
                        .foregroundStyle(NDCColor.onSurface)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(mark.value)
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.primary)
                    Text(mark.tag)
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
            }
            .padding(NDCSpacing.gutter)
            .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mark.name): \(mark.value), \(mark.tag)")
    }
}

// MARK: - Store (marcas reales del atleta)

@MainActor @Observable
final class PerformanceStore {
    struct Data {
        struct Hero {
            let totalPRs: Int
            let deltaLabel: String
            let validatedCount: Int
            let progress: Double
        }
        struct Recent {
            let exercise: String
            let value: String
            let delta: String?
        }
        struct KeyMark: Identifiable {
            let id: UUID
            let icon: String
            let name: String
            let value: String
            let tag: String
        }

        let hero: Hero
        let recent: Recent?
        let keyMarks: [KeyMark]
    }

    private(set) var state: LoadState<Data> = .loading
    private let repo = AthleteRepository()

    func load(athleteId: UUID) async {
        state = .loading
        do {
            let records = try await repo.personalRecords(athleteId: athleteId)
            guard !records.isEmpty else {
                state = .loaded(Data(
                    hero: .init(totalPRs: 0, deltaLabel: "", validatedCount: 0, progress: 0),
                    recent: nil, keyMarks: []
                ))
                return
            }
            let exercises = try await repo.exercises(ids: Array(Set(records.map(\.exerciseId))))
            let exercisesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

            // Hero: total, nuevas en 30 días, % validadas.
            let since = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            let recentCount = records.filter { $0.recordDate >= since }.count
            let validated = records.filter { $0.status == .validado }.count
            let hero = Data.Hero(
                totalPRs: records.count,
                deltaLabel: recentCount > 0 ? "+\(recentCount) este mes" : "",
                validatedCount: validated,
                progress: Double(validated) / Double(records.count)
            )

            // Último logro (marca más reciente).
            var recent: Data.Recent?
            if let latest = records.max(by: { $0.recordDate < $1.recordDate }) {
                let exercise = exercisesById[latest.exerciseId]
                var delta: String?
                if let improvement = latest.improvement, improvement != 0 {
                    let sign = improvement > 0 ? "+" : ""
                    delta = "\(sign)\(latest.scoreType.format(improvement))"
                }
                recent = Data.Recent(
                    exercise: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
                    value: latest.scoreType.format(latest.value),
                    delta: delta
                )
            }

            // Marcas clave: la última de cada ejercicio, por fecha desc.
            let grouped = Dictionary(grouping: records, by: \.exerciseId)
            let marks: [(Date, Data.KeyMark)] = grouped.compactMap { exerciseId, recs in
                guard let latest = recs.max(by: { $0.recordDate < $1.recordDate }) else { return nil }
                let exercise = exercisesById[exerciseId]
                let mark = Data.KeyMark(
                    id: latest.id,
                    icon: exercise?.category.symbol ?? "dumbbell.fill",
                    name: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
                    value: latest.scoreType.format(latest.value),
                    tag: latest.status == .validado ? "Validado" : latest.status.rawValue.capitalized
                )
                return (latest.recordDate, mark)
            }
            state = .loaded(Data(
                hero: hero,
                recent: recent,
                keyMarks: marks.sorted { $0.0 > $1.0 }.map(\.1)
            ))
        } catch {
            state = .failed("No pudimos cargar tu progreso. Revisa tu conexión e inténtalo de nuevo.")
        }
    }
}

#Preview {
    PerformanceView(profile: .preview)
}
