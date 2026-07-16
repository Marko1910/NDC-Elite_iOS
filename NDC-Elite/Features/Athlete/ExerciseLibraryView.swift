import SwiftUI

/// Biblioteca Técnica de Ejercicios — diseño Stitch "Biblioteca Técnica".
/// Intuitiva: búsqueda por nombre + filtro por categoría + lista. Cada ejercicio
/// abre su detalle con el video del coach (YouTube in-app), descripción y pasos.
/// El coach mantiene esta biblioteca subiendo enlaces de YouTube.
/// (ver FLOWS.md → ExerciseLibraryView)
struct ExerciseLibraryView: View {
    @State private var query = ""
    @State private var category: ExerciseCategory?
    private let store = ExerciseLibraryStore.shared

    private func filtered(_ all: [LibraryExercise]) -> [LibraryExercise] {
        all.filter { ex in
            (category == nil || ex.category == category)
            && (query.isEmpty
                || ex.name.localizedCaseInsensitiveContains(query)
                || ex.subtitle.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                categoryFilter
                LoadStateView(state: store.state, retry: { Task { await store.load() } }) { all in
                    let visible = filtered(all)
                    if visible.isEmpty {
                        emptyState
                    } else {
                        ForEach(visible) { ex in
                            // Destino directo (no por value): registrado siempre,
                            // aunque la Biblioteca esté anidada en otro destination.
                            NavigationLink {
                                ExerciseDetailView(exercise: ex)
                            } label: {
                                ExerciseRow(exercise: ex)
                            }
                            .buttonStyle(.plain)
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
        .navigationTitle("Biblioteca Técnica")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Buscar técnica (ej. Snatch, Clean...)")
        .task { await store.load() }
        .refreshable { await store.load() }
    }

    // MARK: - Filtro de categorías

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                filterChip(title: "Todas", selected: category == nil) { category = nil }
                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                    filterChip(title: cat.displayName, selected: category == cat) {
                        category = (category == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(NDCFont.labelBold)
                .foregroundStyle(selected ? .white : NDCColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Sin resultados",
            systemImage: "magnifyingglass",
            description: Text("No encontramos ejercicios para “\(query)”.")
        )
        .padding(.top, NDCSpacing.stackLG)
    }
}

// MARK: - Fila de ejercicio

private struct ExerciseRow: View {
    let exercise: LibraryExercise

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            ZStack {
                NDCColor.primary.opacity(0.10)
                Image(systemName: exercise.category.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(NDCColor.primary)
            }
            .frame(width: 56, height: 56)
            .clipShape(.rect(cornerRadius: NDCRadius.standard))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.subtitle)
                    .font(NDCFont.bodyLG.weight(.semibold))
                    .foregroundStyle(NDCColor.onSurface)
                Text(exercise.name)
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                NDCChip(text: exercise.category.displayName)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name), \(exercise.category.displayName), \(exercise.level.displayName)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Icono por categoría (SF Symbols)

extension ExerciseCategory {
    var symbol: String {
        switch self {
        case .fuerza: "dumbbell.fill"
        case .gimnasia: "figure.gymnastics"
        case .endurance: "figure.run"
        case .movilidad: "figure.cooldown"
        case .olimpico: "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Store compartido (coach escribe en Supabase, atleta lee)

/// Biblioteca técnica real: el coach añade/edita ejercicios desde
/// `ExerciseLibraryManagementView` (persistido en `exercises` +
/// `exercise_technique_steps`); el atleta los consulta aquí mismo.
@Observable
final class ExerciseLibraryStore {
    static let shared = ExerciseLibraryStore()
    private init() {}
    private let repo = ExerciseRepository()

    private(set) var state: LoadState<[LibraryExercise]> = .loading

    func load() async {
        state = .loading
        do {
            state = .loaded(try await repo.fetchLibrary())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func upsert(_ exercise: LibraryExercise, createdBy: UUID) async throws {
        try await repo.upsert(exercise, createdBy: createdBy)
        await load()
    }

    func delete(_ exercise: LibraryExercise) async throws {
        try await repo.delete(id: exercise.id)
        await load()
    }
}

#Preview {
    NavigationStack { ExerciseLibraryView() }
}
