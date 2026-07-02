import SwiftUI

/// Registro de resultado de un WOD — diseño Stitch "Registro de Resultados v2".
/// Se presenta **empujada dentro del tab WOD** (la barra de pestañas inferior
/// permanece visible). Header: ✕ · "Registrar Resultado" · Guardar.
/// (ver FLOWS.md → LogWodResultSheet)
///
/// Carga el WOD del día publicado y, al confirmar, inserta en `wod_results`
/// (status = pendiente; si ya había un resultado pendiente lo reemplaza).
struct LogWodResultView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = LogWodResultStore()

    @State private var doneTasks: Set<Int> = [0]
    @State private var level: AthleteLevel = .intermedio
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var weight = ""
    @State private var unit: WeightUnit = .lbs
    @State private var rpe = 7
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    enum WeightUnit: String, CaseIterable { case lbs = "Lbs", kg = "Kg" }

    var body: some View {
        ScrollView {
            LoadStateView(state: store.state, retry: { Task { await store.load() } }) { info in
                if let info {
                    VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                        wodCard(info)
                        levelSection
                        tasksSection(info.blockTitles)
                        metconResultSection
                        rpeSection
                        notesSection
                        if let errorMessage {
                            Text(errorMessage)
                                .font(NDCFont.labelBold)
                                .foregroundStyle(NDCColor.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        confirmButton
                    }
                } else {
                    ContentUnavailableView(
                        "Sin WOD publicado",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Cuando el coach publique el WOD del día podrás registrar tu resultado aquí.")
                    )
                    .padding(.top, NDCSpacing.stackLG)
                }
            } skeleton: {
                VStack(spacing: NDCSpacing.stackLG) {
                    SkeletonCard(lines: 2, height: 100)
                    SkeletonCard(lines: 3, height: 140)
                    SkeletonCard(lines: 2, height: 120)
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.gutter)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Registrar Resultado")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark").foregroundStyle(NDCColor.onSurface)
                }
                .accessibilityLabel("Cerrar")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "Guardando…" : "Guardar") { Task { await save() } }
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
                    .disabled(isSaving || store.state.value??.wod == nil)
            }
        }
        .task { await store.load() }
    }

    // MARK: - Card del WOD

    private func wodCard(_ info: LogWodResultStore.Info) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(info.wod.title)
                .font(NDCFont.headlineMD)
                .foregroundStyle(.white)
            Text(info.subtitle)
                .font(NDCFont.labelSM)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Nivel al que se hizo el WOD (Principiante/Intermedio/Avanzado)

    private var levelSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Nivel del WOD")
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(AthleteLevel.allCases, id: \.self) { lv in
                    Button {
                        Haptics.selection()
                        level = lv
                    } label: {
                        Text(lv.displayName)
                            .font(NDCFont.labelBold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .foregroundStyle(level == lv ? .white : NDCColor.onSurface)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(level == lv ? NDCColor.primary : NDCColor.surface,
                                        in: .rect(cornerRadius: NDCRadius.standard))
                    }
                    .accessibilityAddTraits(level == lv ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Tareas completadas (bloques del WOD)

    private func tasksSection(_ tasks: [String]) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Tareas Completadas")
            VStack(spacing: 0) {
                ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                    Button {
                        Haptics.selection()
                        if doneTasks.contains(index) { doneTasks.remove(index) }
                        else { doneTasks.insert(index) }
                    } label: {
                        HStack(spacing: NDCSpacing.stackMD) {
                            Image(systemName: doneTasks.contains(index) ? "checkmark.square.fill" : "square")
                                .font(.system(size: 22))
                                .foregroundStyle(doneTasks.contains(index) ? NDCColor.primary : NDCColor.outline)
                            Text(task)
                                .font(NDCFont.bodyMD)
                                .foregroundStyle(NDCColor.onSurface)
                            Spacer()
                        }
                        .padding(NDCSpacing.gutter)
                    }
                    .accessibilityAddTraits(doneTasks.contains(index) ? .isSelected : [])
                    if index < tasks.count - 1 {
                        Divider().overlay(NDCColor.outline.opacity(0.20))
                    }
                }
            }
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Resultado Metcon

    private var metconResultSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Resultado Metcon")
            VStack(spacing: NDCSpacing.gutter) {
                HStack(spacing: NDCSpacing.gutter) {
                    timeField(label: "Minutos", text: $minutes)
                    timeField(label: "Segundos", text: $seconds)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Peso Utilizado")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.outline)
                        Spacer()
                        unitToggle
                    }
                    TextField("Ej: 135", text: $weight)
                        .keyboardType(.numberPad)
                        .font(NDCFont.bodyLG)
                        .padding(NDCSpacing.gutter)
                        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
                }
            }
            .padding(NDCSpacing.stackLG)
            .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
            )
            .shadow(color: NDCColor.primaryDark.opacity(0.08), radius: 12, y: 4)
        }
    }

    private func timeField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.outline)
            TextField("00", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(NDCFont.headlineMD)
                .padding(NDCSpacing.gutter)
                .frame(maxWidth: .infinity)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
        }
    }

    private var unitToggle: some View {
        HStack(spacing: 4) {
            ForEach(WeightUnit.allCases, id: \.self) { u in
                Button {
                    Haptics.selection()
                    unit = u
                } label: {
                    Text(u.rawValue)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(unit == u ? NDCColor.onSurface : NDCColor.outline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background {
                            if unit == u {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(NDCColor.background)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
        .accessibilityLabel("Unidad de peso: \(unit.rawValue)")
    }

    // MARK: - Esfuerzo percibido (RPE)

    private var rpeSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Esfuerzo Percibido (RPE)")
            VStack(spacing: NDCSpacing.stackMD) {
                HStack {
                    Text("Suave (1)")
                    Spacer()
                    Text("Máximo (10)")
                }
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.outline)

                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { value in
                        Button {
                            Haptics.selection()
                            rpe = value
                        } label: {
                            Text("\(value)")
                                .font(NDCFont.labelBold)
                                .foregroundStyle(rpe == value ? .white : NDCColor.onSurface)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .background {
                                    RoundedRectangle(cornerRadius: NDCRadius.standard)
                                        .fill(rpe == value ? NDCColor.primary : NDCColor.surface)
                                        .stroke(rpe == value ? .clear : NDCColor.outline.opacity(0.4), lineWidth: 1)
                                }
                        }
                        .accessibilityLabel("RPE \(value)")
                        .accessibilityAddTraits(rpe == value ? .isSelected : [])
                    }
                }

                Text("\(rpe): \(Self.rpeDescription(rpe))")
                    .font(NDCFont.labelSM)
                    .italic()
                    .foregroundStyle(NDCColor.outline)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Notas

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Notas del Atleta")
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("¿Cómo te sentiste hoy? Ej: Escalé los pesos...")
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.outline)
                        .padding(.horizontal, NDCSpacing.gutter + 4)
                        .padding(.vertical, NDCSpacing.gutter + 8)
                }
                TextEditor(text: $notes)
                    .font(NDCFont.bodyMD)
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .padding(NDCSpacing.stackSM)
            }
            .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Confirmar

    private var confirmButton: some View {
        Button {
            Task { await save() }
        } label: {
            Label(isSaving ? "GUARDANDO…" : "CONFIRMAR RESULTADO", systemImage: "checkmark.circle.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.2), radius: 8, y: 4)
        }
        .disabled(isSaving)
        .padding(.top, NDCSpacing.stackSM)
        .accessibilityHint("Guarda tu resultado para validación del coach")
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.outline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() async {
        guard let wod = store.state.value??.wod, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let mins = Int(minutes) ?? 0
        let secs = Int(seconds) ?? 0
        let timeSeconds: Int? = (mins == 0 && secs == 0) ? nil : mins * 60 + secs
        var weightKg = Double(weight.replacingOccurrences(of: ",", with: "."))
        if unit == .lbs, let w = weightKg {
            weightKg = (w * 0.45359237 * 10).rounded() / 10
        }
        // El RPE viaja en las notas (no hay columna dedicada; el coach lo lee ahí).
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let notesWithRpe = trimmedNotes.isEmpty ? "RPE \(rpe)/10" : "RPE \(rpe)/10 · \(trimmedNotes)"

        do {
            try await AthleteRepository().logWodResult(
                wodId: wod.id,
                timeSeconds: timeSeconds,
                weightUsedKg: weightKg,
                intensity: level,
                notes: notesWithRpe
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar tu resultado. Revisa tu conexión e inténtalo de nuevo."
        }
    }

    private static func rpeDescription(_ value: Int) -> String {
        switch value {
        case ...2: "Muy suave, calentamiento."
        case 3...4: "Suave, sostenible mucho tiempo."
        case 5...6: "Moderado, conversación entrecortada."
        case 7: "Esfuerzo vigoroso, respiración pesada."
        case 8: "Muy duro, pocas palabras."
        case 9: "Casi máximo."
        default: "Máximo esfuerzo."
        }
    }
}

// MARK: - Store (WOD del día real + títulos de sus bloques)

@MainActor @Observable
final class LogWodResultStore {
    struct Info {
        let wod: Wod
        let blockTitles: [String]

        /// "Hoy, Martes 1 de Julio • Fuerza & Metcon"
        var subtitle: String {
            let f = DateFormatter()
            f.locale = Locale(identifier: "es_ES")
            f.dateFormat = "EEEE d 'de' MMMM"
            var label = f.string(from: wod.scheduledDate).capitalized
            if Calendar.current.isDateInToday(wod.scheduledDate) { label = "Hoy, \(label)" }
            if let focus = wod.focus { label += " • \(focus)" }
            return label
        }
    }

    /// `.loaded(nil)` = no hay WOD publicado para hoy o próximo.
    private(set) var state: LoadState<Info?> = .loading
    private let repo = AthleteRepository()

    func load() async {
        state = .loading
        do {
            guard let wod = try await repo.nextWod() else {
                state = .loaded(nil)
                return
            }
            let blocks = try await repo.blocks(for: wod.id)
            let titles = blocks.map { $0.title ?? $0.blockType.displayName }
            state = .loaded(Info(wod: wod, blockTitles: titles.isEmpty ? [wod.title] : titles))
        } catch {
            state = .failed("No pudimos cargar el WOD de hoy.")
        }
    }
}

#Preview {
    NavigationStack { LogWodResultView() }
}
