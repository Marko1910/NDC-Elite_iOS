import SwiftUI

/// Gestión de la Biblioteca Técnica (coach) — alta/edición/borrado de los
/// ejercicios que ve el atleta en `ExerciseLibraryView`. Cada ejercicio incluye
/// el enlace de YouTube que el coach sube y previsualiza dentro de la app.
/// (ver FLOWS.md → ExerciseLibraryManagementView)
struct ExerciseLibraryManagementView: View {
    let profile: Profile
    private let store = ExerciseLibraryStore.shared
    @State private var query = ""
    @State private var editingExercise: LibraryExercise?
    @State private var showEditor = false

    private func filtered(_ all: [LibraryExercise]) -> [LibraryExercise] {
        query.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                LoadStateView(state: store.state, retry: { Task { await store.load() } }) { all in
                    let visible = filtered(all)
                    if visible.isEmpty {
                        ContentUnavailableView(
                            "Biblioteca vacía",
                            systemImage: "video.badge.plus",
                            description: Text("Añade tu primer ejercicio con su video de técnica.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        ForEach(visible) { exercise in
                            Button {
                                Haptics.impact(.light)
                                editingExercise = exercise
                                showEditor = true
                            } label: {
                                ManagementRow(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task { try? await store.delete(exercise) }
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        }
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackSM) {
                        SkeletonCard(lines: 2, height: 64)
                        SkeletonCard(lines: 2, height: 64)
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
        .searchable(text: $query, prompt: "Buscar ejercicio...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.impact()
                    editingExercise = nil
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Añadir ejercicio")
            }
        }
        .sheet(isPresented: $showEditor) {
            ExerciseEditorView(profile: profile, exercise: editingExercise)
        }
        .task { await store.load() }
        .refreshable { await store.load() }
    }
}

// MARK: - Fila de gestión

private struct ManagementRow: View {
    let exercise: LibraryExercise

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            ZStack {
                NDCColor.primary.opacity(0.10)
                Image(systemName: YouTube.videoID(from: exercise.youtubeURL) != nil ? "play.circle.fill" : "video.slash")
                    .font(.system(size: 20))
                    .foregroundStyle(NDCColor.primary)
            }
            .frame(width: 48, height: 48)
            .clipShape(.rect(cornerRadius: NDCRadius.standard))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name).font(NDCFont.bodyLG.weight(.semibold)).foregroundStyle(NDCColor.onSurface)
                Text(exercise.subtitle).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                NDCChip(text: exercise.category.displayName).padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.20), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(exercise.name), editar")
    }
}

#Preview {
    NavigationStack { ExerciseLibraryManagementView(profile: .preview) }
}
