import SwiftUI

/// Registrar Nueva Marca (PR) — diseño Stitch "Registrar Nueva Marca".
/// Se presenta como **bottom sheet** (grabber + detents) desde el FAB de
/// Progreso. Campos: ejercicio · resultado + fecha · notas · Guardar / Cancelar.
/// (ver FLOWS.md → LogPrSheet)
///
/// El picker lista los `exercises` reales de la Biblioteca Técnica y al guardar
/// inserta en `personal_records` (status = pendiente, con `previous_value`).
struct LogPrSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var exercises: LoadState<[Exercise]> = .loading
    @State private var exercise: Exercise?
    @State private var result = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var resultValue: Double? {
        Double(result.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    exerciseField
                    HStack(alignment: .top, spacing: NDCSpacing.gutter) {
                        resultField
                        dateField
                    }
                    notesField
                    if let errorMessage {
                        Text(errorMessage)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.error)
                    }
                    actions
                }
                .padding(NDCSpacing.marginMain)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(NDCColor.surface)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .task { await loadExercises() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Nueva Marca")
                .font(NDCFont.headlineMD)
                .foregroundStyle(NDCColor.primary)
            Spacer()
            Button {
                Haptics.impact(.light)
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(NDCColor.outline)
            }
            .accessibilityLabel("Cerrar")
        }
        .padding(.horizontal, NDCSpacing.marginMain)
        .padding(.top, NDCSpacing.stackMD)
        .padding(.bottom, NDCSpacing.stackSM)
    }

    // MARK: - Ejercicio (picker de la biblioteca real)

    private var exerciseField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Ejercicio")
            Menu {
                if case .loaded(let all) = exercises {
                    ForEach(all) { ex in
                        Button(ex.nameEs ?? ex.name) {
                            Haptics.selection()
                            exercise = ex
                        }
                    }
                }
            } label: {
                HStack(spacing: NDCSpacing.stackSM) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NDCColor.outline)
                    Text(exerciseFieldText)
                        .font(NDCFont.bodyLG)
                        .foregroundStyle(exercise == nil ? NDCColor.outline : NDCColor.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(NDCColor.primary)
                }
                .padding(.horizontal, NDCSpacing.gutter)
                .frame(height: 48)
                .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
            }
            .accessibilityLabel("Ejercicio")
            .accessibilityValue(exercise.map { $0.nameEs ?? $0.name } ?? "Sin seleccionar")

            if case .failed = exercises {
                Button("No se pudo cargar la biblioteca. Reintentar") {
                    Task { await loadExercises() }
                }
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.error)
            }
        }
    }

    private var exerciseFieldText: String {
        if let exercise { return exercise.nameEs ?? exercise.name }
        return exercises.isLoading ? "Cargando ejercicios…" : "Buscar ejercicio (ej. Back Squat)"
    }

    // MARK: - Resultado + Fecha

    private var resultField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Resultado")
            HStack {
                TextField("0.0", text: $result)
                    .keyboardType(.decimalPad)
                    .font(NDCFont.bodyLG)
                Text(unitLabel)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.outline)
            }
            .padding(.horizontal, NDCSpacing.gutter)
            .frame(height: 48)
            .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
        }
    }

    /// La unidad sigue al tipo de marca del ejercicio elegido.
    private var unitLabel: String {
        switch exercise?.defaultScoreType {
        case .tiempo: "SEG"
        case .reps: "REPS"
        case .rondas: "RONDAS"
        case .distancia: "KM"
        case .calorias: "CAL"
        case .peso, nil: "KG"
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Fecha")
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(NDCColor.outline)
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(NDCColor.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, NDCSpacing.gutter)
            .frame(height: 48)
            .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
        }
    }

    // MARK: - Notas

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Notas (Opcional)")
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("¿Cómo te sentiste hoy?")
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.outline)
                        .padding(.horizontal, NDCSpacing.gutter + 4)
                        .padding(.vertical, NDCSpacing.gutter)
                }
                TextEditor(text: $notes)
                    .font(NDCFont.bodyMD)
                    .frame(minHeight: 80)
                    .scrollContentBackground(.hidden)
                    .padding(NDCSpacing.stackSM)
            }
            .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
        }
    }

    // MARK: - Acciones

    private var actions: some View {
        VStack(spacing: NDCSpacing.stackMD) {
            Button {
                Task { await save() }
            } label: {
                Label(isSaving ? "Guardando…" : "Guardar Marca", systemImage: "square.and.arrow.down")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            }
            .disabled(exercise == nil || resultValue == nil || isSaving)
            .opacity(exercise == nil || resultValue == nil ? 0.6 : 1)
            .accessibilityHint("Guarda la marca para validación del coach")

            Button("Cancelar") {
                Haptics.impact(.light)
                dismiss()
            }
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.primary)
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .padding(.top, NDCSpacing.stackSM)
    }

    // MARK: - Helpers

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.onSurfaceVariant)
    }

    private func loadExercises() async {
        exercises = .loading
        do {
            exercises = .loaded(try await AthleteRepository().allExercises())
        } catch {
            exercises = .failed(error.localizedDescription)
        }
    }

    private func save() async {
        guard let exercise, let value = resultValue, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await AthleteRepository().logPersonalRecord(
                exerciseId: exercise.id,
                value: value,
                scoreType: exercise.defaultScoreType,
                recordDate: date,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la marca. Revisa tu conexión e inténtalo de nuevo."
        }
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) { LogPrSheet() }
}
