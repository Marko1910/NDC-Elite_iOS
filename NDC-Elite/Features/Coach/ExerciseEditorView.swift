import SwiftUI

/// Editor de Ejercicio (coach) — alta/edición de un ejercicio de la Biblioteca
/// Técnica. El coach pega el enlace de YouTube y lo previsualiza **dentro de
/// la app** antes de guardar; el atleta luego lo reproduce en `ExerciseDetailView`.
/// (ver FLOWS.md → ExerciseEditorView)
///
struct ExerciseEditorView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    private let store = ExerciseLibraryStore.shared
    private let editingID: UUID?

    @State private var name: String
    @State private var subtitle: String
    @State private var category: ExerciseCategory
    @State private var level: AthleteLevel
    @State private var youtubeURL: String
    @State private var summary: String
    @State private var steps: [LibraryExercise.Step]
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(profile: Profile, exercise: LibraryExercise? = nil) {
        self.profile = profile
        editingID = exercise?.id
        _name = State(initialValue: exercise?.name ?? "")
        _subtitle = State(initialValue: exercise?.subtitle ?? "")
        _category = State(initialValue: exercise?.category ?? .fuerza)
        _level = State(initialValue: exercise?.level ?? .basico)
        _youtubeURL = State(initialValue: exercise?.youtubeURL ?? "")
        _summary = State(initialValue: exercise?.summary ?? "")
        _steps = State(initialValue: exercise?.steps ?? [])
    }

    private var videoID: String? { YouTube.videoID(from: youtubeURL) }
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && videoID != nil && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    field("Nombre") { TextField("Ej: Back Squat", text: $name) }
                    field("Subtítulo") { TextField("Ej: Sentadilla por detrás", text: $subtitle) }
                    categorySection
                    levelSection
                    field("Enlace de YouTube") {
                        TextField("https://youtube.com/watch?v=...", text: $youtubeURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    videoPreview
                    field("Descripción") { descriptionEditor }
                    stepsSection
                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle(editingID == nil ? "Nuevo Ejercicio" : "Editar Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Guardando…" : "Guardar") { Task { await save() } }
                        .font(NDCFont.labelBold)
                        .foregroundStyle(canSave ? NDCColor.primary : NDCColor.outline)
                        .disabled(!canSave)
                }
            }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Categoría / Nivel

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text("CATEGORÍA").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NDCSpacing.stackSM) {
                    ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                        chip(cat.displayName, selected: category == cat) { category = cat }
                    }
                }
            }
        }
    }

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text("NIVEL").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(AthleteLevel.allCases, id: \.self) { lv in
                    chip(lv.displayName, selected: level == lv) { level = lv }
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
                .background(selected ? NDCColor.primary : NDCColor.primary.opacity(0.1), in: .capsule)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Previsualización del video (misma vista que verá el atleta)

    @ViewBuilder
    private var videoPreview: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text("PREVISUALIZACIÓN").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            if let videoID {
                YouTubePlayerView(videoID: videoID)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: NDCRadius.large))
            } else {
                ZStack {
                    NDCColor.surfaceStrong
                    VStack(spacing: NDCSpacing.stackSM) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 28)).foregroundStyle(NDCColor.outline)
                        Text(youtubeURL.isEmpty ? "Pega un enlace de YouTube para previsualizar" : "Enlace no reconocido")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                            .multilineTextAlignment(.center)
                    }
                }
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(.rect(cornerRadius: NDCRadius.large))
            }
        }
    }

    // MARK: - Descripción

    private var descriptionEditor: some View {
        ZStack(alignment: .topLeading) {
            if summary.isEmpty {
                Text("Explica el ejercicio y su objetivo...")
                    .font(NDCFont.bodyMD).foregroundStyle(NDCColor.outline)
                    .padding(.horizontal, NDCSpacing.stackSM).padding(.vertical, 8)
            }
            TextEditor(text: $summary)
                .font(NDCFont.bodyMD).frame(minHeight: 90)
                .scrollContentBackground(.hidden)
        }
    }

    // MARK: - Pasos de técnica

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("TÉCNICA PASO A PASO").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                Spacer()
                Button {
                    Haptics.impact(.light)
                    steps.append(.init(title: "", detail: ""))
                } label: {
                    Label("Añadir paso", systemImage: "plus.circle.fill")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                }
            }
            ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                StepEditorRow(
                    title: Binding(get: { steps[index].title }, set: { steps[index] = .init(title: $0, detail: steps[index].detail) }),
                    detail: Binding(get: { steps[index].detail }, set: { steps[index] = .init(title: steps[index].title, detail: $0) }),
                    onDelete: { steps.remove(at: index) }
                )
            }
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG).padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private func save() async {
        guard let videoID else { return }
        let exercise = LibraryExercise(
            id: editingID ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            subtitle: subtitle.trimmingCharacters(in: .whitespaces),
            category: category,
            level: level,
            youtubeURL: "https://www.youtube.com/watch?v=\(videoID)",
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: steps.filter { !$0.title.trimmingCharacters(in: .whitespaces).isEmpty }
        )
        isSaving = true
        errorMessage = nil
        do {
            try await store.upsert(exercise, createdBy: profile.id)
            Haptics.notify(.success)
            dismiss()
        } catch {
            isSaving = false
            errorMessage = "No se pudo guardar. ¿El nombre ya existe en la biblioteca?"
        }
    }
}

// MARK: - Fila de paso editable

private struct StepEditorRow: View {
    @Binding var title: String
    @Binding var detail: String
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                TextField("Título (ej: Setup)", text: $title)
                    .font(NDCFont.bodyMD.weight(.bold))
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").foregroundStyle(NDCColor.error)
                }
            }
            TextField("Detalle del paso...", text: $detail, axis: .vertical)
                .font(NDCFont.bodyMD)
                .lineLimit(1...4)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }
}

#Preview {
    ExerciseEditorView(profile: .preview)
}
