import SwiftUI

/// PRs de Atletas (coach) — pantalla nueva (no está en `diseño/`), construida
/// con el design system NDC. Lista todas las marcas personales del box, más
/// recientes primero, con búsqueda por atleta/ejercicio y filtro por estado.
/// Se llega desde Progreso (ícono de trofeo o "Ver todo" de PRs Recientes).
struct CoachPrsView: View {
    @State private var store = CoachPrsStore()
    @State private var query = ""
    @State private var statusFilter: ResultStatus?

    private func filtered(_ items: [CoachPrsStore.Item]) -> [CoachPrsStore.Item] {
        items.filter { item in
            let matchesQuery = query.isEmpty
                || item.athleteName.localizedCaseInsensitiveContains(query)
                || item.exerciseName.localizedCaseInsensitiveContains(query)
            let matchesStatus = statusFilter == nil || item.status == statusFilter
            return matchesQuery && matchesStatus
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                statusChips
                LoadStateView(state: store.state, retry: { Task { await store.load() } }) { items in
                    let visible = filtered(items)
                    if visible.isEmpty {
                        ContentUnavailableView(
                            "Sin marcas",
                            systemImage: "trophy",
                            description: Text(items.isEmpty
                                ? "Cuando los atletas registren PRs aparecerán aquí."
                                : "No hay marcas para este filtro.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        ForEach(visible) { item in
                            PrRow(item: item)
                        }
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

    // MARK: - Filtro por estado

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

    private var statusColor: Color {
        switch item.status {
        case .pendiente: NDCColor.onAccent
        case .validado: .green
        case .corregido: NDCColor.secondary
        }
    }

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: item.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.athleteName).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("\(item.exerciseName) · \(item.dateLabel)")
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

// MARK: - Store (todas las marcas + nombres de atletas/ejercicios)

@MainActor @Observable
final class CoachPrsStore {
    struct Item: Identifiable {
        let id: UUID
        let athleteName: String
        let avatarURL: String?
        let exerciseName: String
        let valueLabel: String
        let dateLabel: String
        let status: ResultStatus
    }

    private(set) var state: LoadState<[Item]> = .loading
    private let repo = CoachRepository()

    func load() async {
        state = .loading
        do {
            let records = try await repo.allPersonalRecords()
            async let profilesTask = repo.profiles(ids: Array(Set(records.map(\.athleteId))))
            async let exercisesTask = AthleteRepository().exercises(ids: Array(Set(records.map(\.exerciseId))))
            let profilesById = Dictionary(uniqueKeysWithValues: (try await profilesTask).map { ($0.id, $0) })
            let exercisesById = Dictionary(uniqueKeysWithValues: (try await exercisesTask).map { ($0.id, $0) })

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "es_ES")
            formatter.dateFormat = "d MMM"

            state = .loaded(records.map { record in
                let profile = profilesById[record.athleteId]
                let exercise = exercisesById[record.exerciseId]
                return Item(
                    id: record.id,
                    athleteName: profile?.fullName ?? "Atleta",
                    avatarURL: profile?.avatarURL,
                    exerciseName: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
                    valueLabel: record.scoreType.format(record.value),
                    dateLabel: Calendar.current.isDateInToday(record.recordDate)
                        ? "Hoy" : formatter.string(from: record.recordDate),
                    status: record.status
                )
            })
        } catch {
            state = .failed("No se pudieron cargar las marcas del box.")
        }
    }
}

#Preview {
    NavigationStack { CoachPrsView() }
}
