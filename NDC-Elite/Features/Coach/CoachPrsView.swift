import SwiftUI

/// PRs de Atletas (coach) — pantalla nueva (no está en `diseño/`), construida
/// con el design system NDC. Muestra **todos los atletas** del box; al entrar
/// a uno se ven todas sus marcas. La búsqueda encuentra por **atleta o por
/// ejercicio** y muestra las marcas que coincidan.
/// Se llega desde Progreso (ícono de trofeo o "Ver todo" de PRs Recientes).
struct CoachPrsView: View {
    @State private var store = CoachPrsStore()
    @State private var query = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                LoadStateView(state: store.state, retry: { Task { await store.load() } }) { data in
                    if query.isEmpty {
                        athleteList(data)
                    } else {
                        searchResults(data)
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackSM) {
                        SkeletonCard(lines: 2, height: 72)
                        SkeletonCard(lines: 2, height: 72)
                        SkeletonCard(lines: 2, height: 72)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackSM)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("PRs de Atletas")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Buscar por atleta o ejercicio...")
        .task { await store.load() }
        .refreshable { await store.load() }
    }

    // MARK: - Lista de atletas (sin búsqueda)

    @ViewBuilder
    private func athleteList(_ data: CoachPrsStore.Data) -> some View {
        if data.athletes.isEmpty {
            ContentUnavailableView(
                "Sin atletas",
                systemImage: "person.3",
                description: Text("Cuando haya atletas en el box aparecerán aquí.")
            )
            .padding(.top, NDCSpacing.stackLG)
        } else {
            Text("\(data.athletes.count) atletas")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            ForEach(data.athletes) { athlete in
                NavigationLink {
                    AthletePrsDetailView(athlete: athlete, records: data.records(of: athlete.id))
                } label: {
                    AthletePrsRow(athlete: athlete, records: data.records(of: athlete.id))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Resultados de búsqueda (por atleta o ejercicio)

    @ViewBuilder
    private func searchResults(_ data: CoachPrsStore.Data) -> some View {
        let matches = data.items.filter {
            $0.athleteName.localizedCaseInsensitiveContains(query)
            || $0.exerciseName.localizedCaseInsensitiveContains(query)
        }
        if matches.isEmpty {
            ContentUnavailableView(
                "Sin resultados",
                systemImage: "magnifyingglass",
                description: Text("No hay marcas de atletas o ejercicios que coincidan con “\(query)”.")
            )
            .padding(.top, NDCSpacing.stackLG)
        } else {
            Text("\(matches.count) marcas")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            ForEach(matches) { item in
                PrRow(item: item, showAthlete: true)
            }
        }
    }
}

// MARK: - Fila de atleta (resumen de sus PRs)

private struct AthletePrsRow: View {
    let athlete: Profile
    let records: [CoachPrsStore.Item]

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.fullName).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("\(athlete.level.displayName) · \(records.count) marcas")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            if let latest = records.first {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(latest.valueLabel).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                    Text(latest.exerciseName).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
            }
            Image(systemName: "chevron.right").foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(athlete.fullName), \(records.count) marcas registradas")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Detalle: todos los PRs de un atleta

private struct AthletePrsDetailView: View {
    let athlete: Profile
    let records: [CoachPrsStore.Item]
    @State private var statusFilter: ResultStatus?

    private var visible: [CoachPrsStore.Item] {
        statusFilter == nil ? records : records.filter { $0.status == statusFilter }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                header
                statusChips
                if visible.isEmpty {
                    ContentUnavailableView(
                        "Sin marcas",
                        systemImage: "trophy",
                        description: Text(records.isEmpty
                            ? "Este atleta aún no registra PRs."
                            : "No hay marcas con este estado.")
                    )
                    .padding(.top, NDCSpacing.stackLG)
                } else {
                    ForEach(visible) { item in
                        PrRow(item: item, showAthlete: false)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackSM)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle(athlete.fullName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.fullName).font(NDCFont.headlineSM).foregroundStyle(.white)
                Text("\(athlete.level.displayName) · \(records.count) marcas registradas")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            Spacer()
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .combine)
    }

    private var statusChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                chip("Todos", selected: statusFilter == nil) { statusFilter = nil }
                ForEach(ResultStatus.allCases, id: \.self) { status in
                    chip(status.rawValue.capitalized, selected: statusFilter == status) {
                        statusFilter = (statusFilter == status) ? nil : status
                    }
                }
            }
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(NDCFont.labelBold)
                .foregroundStyle(selected ? .white : NDCColor.primary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(selected ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Fila de PR

private struct PrRow: View {
    let item: CoachPrsStore.Item
    var showAthlete = true

    private var statusColor: Color {
        switch item.status {
        case .pendiente: NDCColor.onAccent
        case .validado: .green
        case .corregido: NDCColor.secondary
        }
    }

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            if showAthlete {
                NDCAvatarView(urlString: item.avatarURL, size: 44)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(showAthlete ? item.athleteName : item.exerciseName)
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text(showAthlete ? "\(item.exerciseName) · \(item.dateLabel)" : item.dateLabel)
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(item.valueLabel).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Text(item.status.rawValue.uppercased())
                    .font(NDCFont.labelSM).foregroundStyle(statusColor)
            }
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.athleteName), \(item.exerciseName): \(item.valueLabel), \(item.status.rawValue)")
    }
}

// MARK: - Store (atletas + todas las marcas)

@MainActor @Observable
final class CoachPrsStore {
    struct Item: Identifiable {
        let id: UUID
        let athleteId: UUID
        let athleteName: String
        let avatarURL: String?
        let exerciseName: String
        let valueLabel: String
        let dateLabel: String
        let status: ResultStatus
    }

    struct Data {
        /// Todos los atletas del box (incluidos los que aún no tienen PRs).
        let athletes: [Profile]
        /// Todas las marcas, más recientes primero.
        let items: [Item]
        private let byAthlete: [UUID: [Item]]

        init(athletes: [Profile], items: [Item]) {
            self.athletes = athletes
            self.items = items
            byAthlete = Dictionary(grouping: items, by: \.athleteId)
        }

        func records(of athleteId: UUID) -> [Item] {
            byAthlete[athleteId] ?? []
        }
    }

    private(set) var state: LoadState<Data> = .loading
    private let repo = CoachRepository()

    func load() async {
        if state.value == nil { state = .loading }
        do {
            async let athletesTask = repo.athletes()
            async let recordsTask = repo.allPersonalRecords()
            let (athletes, records) = try await (athletesTask, recordsTask)
            let profilesById = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0) })
            let exercisesById = Dictionary(
                uniqueKeysWithValues: try await AthleteRepository()
                    .exercises(ids: Array(Set(records.map(\.exerciseId))))
                    .map { ($0.id, $0) }
            )

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.dateFormat = "d MMM"

            let items = records.map { record in
                let profile = profilesById[record.athleteId]
                let exercise = exercisesById[record.exerciseId]
                return Item(
                    id: record.id,
                    athleteId: record.athleteId,
                    athleteName: profile?.fullName ?? "Atleta",
                    avatarURL: profile?.avatarURL,
                    exerciseName: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
                    valueLabel: record.scoreType.format(record.value),
                    dateLabel: Calendar.current.isDateInToday(record.recordDate)
                        ? "Hoy" : formatter.string(from: record.recordDate),
                    status: record.status
                )
            }
            state = .loaded(Data(athletes: athletes, items: items))
        } catch {
            state = .failed("No se pudieron cargar las marcas del box.")
        }
    }
}

#Preview {
    NavigationStack { CoachPrsView() }
}
