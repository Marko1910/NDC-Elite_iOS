import SwiftUI

/// Editor de WOD (coach) — diseño Stitch "Editor de WOD - Flujo de Ejercicios".
/// Crea/edita el WOD del día: fecha, nombre, tipo, time cap, y tres bloques fijos
/// (Calentamiento · Fuerza/Técnica · Metcon) que el coach arma desde cero,
/// añadiendo ejercicios de la Biblioteca Técnica real (con su video). Publicar
/// o guardar borrador. (ver FLOWS.md → WodEditorView)
struct WodEditorView: View {
    let profile: Profile
    /// `nil` = WOD nuevo (bloques vacíos); si no, precarga el WOD existente.
    var existingWod: Wod?

    @Environment(\.dismiss) private var dismiss
    private let repo = WodRepository()

    @State private var date = Date()
    @State private var name = ""
    @State private var type: WodType = .amrap
    @State private var timeCap = ""
    @State private var blocks: [EditableBlock] = EditableBlock.emptyDefaults
    @State private var isLoading: Bool
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var pickerTargetBlockID: EditableBlock.ID?
    @State private var isNamingNewBlock = false
    @State private var newBlockName = ""

    init(profile: Profile, existingWod: Wod? = nil) {
        self.profile = profile
        self.existingWod = existingWod
        _isLoading = State(initialValue: existingWod != nil)
    }

    struct EditableBlock: Identifiable {
        let id = UUID()
        let type: BlockType
        var title: String
        let icon: String
        /// Los bloques personalizados (creados por el coach con su propio
        /// nombre) se pueden eliminar; los tres fijos no.
        var isCustom = false
        var exercises: [EditableExercise] = []

        static var emptyDefaults: [EditableBlock] {
            [
                .init(type: .calentamiento, title: "Calentamiento", icon: "leaf.fill"),
                .init(type: .fuerza, title: "Fuerza / Técnica", icon: "dumbbell.fill"),
                .init(type: .metcon, title: "Metcon", icon: "timer")
            ]
        }
    }

    struct EditableExercise: Identifiable {
        let id = UUID()
        let exercise: LibraryExercise
        var prescription: String = ""
    }

    var body: some View {
        ScrollView {
            if isLoading {
                VStack(spacing: NDCSpacing.stackLG) {
                    SkeletonCard(lines: 3, height: 120)
                    SkeletonCard(lines: 4, height: 160)
                }
                .padding(NDCSpacing.marginMain)
            } else {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Text(existingWod == nil ? "Nuevo WOD del Día" : "Editar WOD").font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)

                    field("Fecha de Programación") {
                        DatePicker("", selection: $date, displayedComponents: .date).labelsHidden().tint(NDCColor.primary)
                    }
                    field("Nombre del WOD") { TextField("Ej: El Desafío Híbrido", text: $name) }

                    VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                        Text("TIPO").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: NDCSpacing.stackSM) {
                                ForEach(WodType.allCases, id: \.self) { t in
                                    Button {
                                        Haptics.selection(); type = t
                                    } label: {
                                        Text(t.displayName)
                                            .font(NDCFont.labelBold)
                                            .foregroundStyle(type == t ? .white : NDCColor.primary)
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(type == t ? NDCColor.primary : NDCColor.primary.opacity(0.1), in: .capsule)
                                    }
                                }
                            }
                        }
                    }
                    field("Time Cap (min)") { TextField("20", text: $timeCap).keyboardType(.numberPad) }

                    Text("Estructura del Bloque").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                    ForEach($blocks) { $block in
                        BlockEditor(
                            block: $block,
                            onAddExercise: { pickerTargetBlockID = block.id },
                            onDelete: block.isCustom ? { blocks.removeAll { $0.id == block.id } } : nil
                        )
                    }
                    addBlockButton

                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
                .padding(.bottom, 100)
            }
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Creador de Entrenamientos")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !isLoading {
                HStack(spacing: NDCSpacing.stackMD) {
                    Button {
                        Task { await save(status: .borrador) }
                    } label: {
                        Text("Guardar Borrador").font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.primary, lineWidth: 1))
                    }
                    Button {
                        Task { await save(status: .publicado) }
                    } label: {
                        Label(isSaving ? "Guardando…" : "Publicar", systemImage: "checkmark.circle.fill").font(NDCFont.headlineSM).foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                    }
                }
                .disabled(isSaving || name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackSM)
                .background(.ultraThinMaterial)
            }
        }
        .alert("Nuevo bloque", isPresented: $isNamingNewBlock) {
            TextField("Ej: Fuerza, Metcon, Core…", text: $newBlockName)
            Button("Cancelar", role: .cancel) { newBlockName = "" }
            Button("Crear") {
                let trimmed = newBlockName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    blocks.append(EditableBlock(type: .accesorio, title: trimmed,
                                                icon: "square.stack.3d.up.fill", isCustom: true))
                }
                newBlockName = ""
            }
        } message: {
            Text("Dale un nombre a la nueva caja de ejercicios.")
        }
        .sheet(item: $pickerTargetBlockID) { blockID in
            ExercisePickerSheet { exercise in
                if let index = blocks.firstIndex(where: { $0.id == blockID }) {
                    blocks[index].exercises.append(EditableExercise(exercise: exercise))
                }
            }
        }
        .task { await loadExistingIfNeeded() }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG).padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private var addBlockButton: some View {
        Button {
            Haptics.impact(.light)
            isNamingNewBlock = true
        } label: {
            Label("Añadir Bloque", systemImage: "plus.rectangle.on.rectangle")
                .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: NDCRadius.large)
                        .stroke(NDCColor.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
        }
    }

    // MARK: - Carga (editar WOD existente)

    private func loadExistingIfNeeded() async {
        await ExerciseLibraryStore.shared.load()
        guard let existingWod else { isLoading = false; return }
        date = existingWod.scheduledDate
        name = existingWod.title
        type = existingWod.wodType
        timeCap = existingWod.timeCapMinutes.map(String.init) ?? ""
        do {
            let fetchedBlocks = try await repo.fetchBlocks(wodId: existingWod.id)
            let exerciseRows = try await repo.fetchBlockExercises(blockIds: fetchedBlocks.map(\.id))
            let library = ExerciseLibraryStore.shared.state.value ?? []

            func exercises(of block: WodBlock) -> [EditableExercise] {
                exerciseRows
                    .filter { $0.blockId == block.id }
                    .compactMap { row -> EditableExercise? in
                        guard let exId = row.exerciseId, let exercise = library.first(where: { $0.id == exId }) else { return nil }
                        return EditableExercise(exercise: exercise, prescription: row.prescription)
                    }
            }

            var loaded: [EditableBlock] = []
            var consumed = Set<UUID>()
            for defaultBlock in EditableBlock.emptyDefaults {
                guard let match = fetchedBlocks.first(where: { $0.blockType == defaultBlock.type && !consumed.contains($0.id) }) else {
                    loaded.append(defaultBlock)
                    continue
                }
                consumed.insert(match.id)
                loaded.append(EditableBlock(type: defaultBlock.type, title: defaultBlock.title,
                                            icon: defaultBlock.icon, exercises: exercises(of: match)))
            }
            // Bloques personalizados del coach (los que no son de los tres fijos).
            for extra in fetchedBlocks where !consumed.contains(extra.id) {
                loaded.append(EditableBlock(type: extra.blockType,
                                            title: extra.title ?? extra.blockType.displayName,
                                            icon: "square.stack.3d.up.fill",
                                            isCustom: true,
                                            exercises: exercises(of: extra)))
            }
            blocks = loaded
        } catch {
            errorMessage = "No se pudo cargar el WOD completo."
        }
        isLoading = false
    }

    // MARK: - Guardar

    private func save(status: WodStatus) async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await repo.saveWod(
                id: existingWod?.id ?? UUID(),
                title: name.trimmingCharacters(in: .whitespaces),
                scheduledDate: date,
                wodType: type,
                status: status,
                timeCapMinutes: Int(timeCap),
                createdBy: profile.id,
                blocks: blocks.map { block in
                    WodEditorBlockInput(
                        type: block.type,
                        title: block.title,
                        exercises: block.exercises.map {
                            WodEditorExerciseInput(exerciseId: $0.exercise.id, exerciseName: $0.exercise.name, prescription: $0.prescription)
                        }
                    )
                }
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            errorMessage = "No se pudo guardar el WOD. Intenta de nuevo."
        }
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

// MARK: - Bloque editable

private struct BlockEditor: View {
    @Binding var block: WodEditorView.EditableBlock
    let onAddExercise: () -> Void
    /// Solo los bloques personalizados traen acción de eliminar.
    var onDelete: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Label(block.title, systemImage: block.icon)
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                Spacer()
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash").foregroundStyle(NDCColor.error)
                    }
                    .accessibilityLabel("Eliminar bloque \(block.title)")
                }
            }

            if block.exercises.isEmpty {
                Text("Sin ejercicios todavía.")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            } else {
                ForEach($block.exercises) { $item in
                    ExerciseEntryRow(item: $item, onRemove: {
                        block.exercises.removeAll { $0.id == item.id }
                    })
                }
            }

            Button {
                Haptics.impact(.light)
                onAddExercise()
            } label: {
                Label("Añadir Ejercicio de Biblioteca…", systemImage: "plus")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }
}

// MARK: - Ejercicio dentro del bloque (con video + prescripción)

private struct ExerciseEntryRow: View {
    @Binding var item: WodEditorView.EditableExercise
    let onRemove: () -> Void
    /// El video de técnica va colapsado: solo el nombre + ojo desplegable
    /// (el mismo ojo que verá el atleta para revisar la técnica).
    @State private var showTechnique = false

    private var videoID: String? { YouTube.videoID(from: item.exercise.youtubeURL) }

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                Text(item.exercise.name).font(NDCFont.bodyMD.weight(.bold)).foregroundStyle(NDCColor.onSurface)
                Spacer()
                if videoID != nil {
                    Button {
                        Haptics.selection()
                        withAnimation(.snappy) { showTechnique.toggle() }
                    } label: {
                        Image(systemName: showTechnique ? "eye.fill" : "eye")
                            .foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel(showTechnique ? "Ocultar técnica de \(item.exercise.name)" : "Ver técnica de \(item.exercise.name)")
                }
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash").foregroundStyle(NDCColor.error)
                }
            }
            if showTechnique, let videoID {
                YouTubeThumbnailPlayer(videoID: videoID)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: NDCRadius.standard))
                    .frame(maxHeight: 160)
            }
            TextField("Prescripción, ej: 5 Sets de 3 Reps al 75% RM", text: $item.prescription, axis: .vertical)
                .font(NDCFont.bodyMD)
                .padding(NDCSpacing.stackSM)
                .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.standard))
        }
        .padding(.vertical, NDCSpacing.stackSM)
    }
}

// MARK: - Selector de ejercicios de la Biblioteca Técnica (real)

private struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSelect: (LibraryExercise) -> Void
    @State private var query = ""

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: ExerciseLibraryStore.shared.state,
                retry: { Task { await ExerciseLibraryStore.shared.load() } }
            ) { all in
                let visible = query.isEmpty ? all : all.filter { $0.name.localizedCaseInsensitiveContains(query) }
                ScrollView {
                    VStack(spacing: NDCSpacing.stackSM) {
                        if visible.isEmpty {
                            ContentUnavailableView(
                                "Biblioteca vacía",
                                systemImage: "video.badge.plus",
                                description: Text("Primero crea ejercicios en la Biblioteca Técnica.")
                            )
                            .padding(.top, NDCSpacing.stackLG)
                        } else {
                            ForEach(visible) { exercise in
                                Button {
                                    Haptics.impact(.light)
                                    onSelect(exercise)
                                    dismiss()
                                } label: {
                                    HStack(spacing: NDCSpacing.gutter) {
                                        Image(systemName: exercise.category.symbol).foregroundStyle(NDCColor.primary)
                                            .frame(width: 40, height: 40).background(NDCColor.primary.opacity(0.1), in: .circle)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(exercise.name).font(NDCFont.bodyLG.weight(.semibold)).foregroundStyle(NDCColor.onSurface)
                                            Text(exercise.subtitle).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                                        }
                                        Spacer()
                                    }
                                    .padding(NDCSpacing.gutter)
                                    .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(NDCSpacing.marginMain)
                }
            } skeleton: {
                ProgressView().padding(.top, NDCSpacing.stackLG)
            }
            .navigationTitle("Biblioteca Técnica")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Buscar ejercicio...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .tint(NDCColor.primary)
    }
}

#Preview {
    NavigationStack { WodEditorView(profile: .preview) }
}
