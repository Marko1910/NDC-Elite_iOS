import SwiftUI

/// Registrar Nueva Marca (PR) — diseño Stitch "Registrar Nueva Marca".
/// Se presenta como **bottom sheet** (grabber + detents) desde el FAB de
/// Progreso. Campos: ejercicio · resultado + fecha · notas · Guardar / Cancelar.
/// (ver FLOWS.md → LogPrSheet)
///
/// TODO(datos): hoy usa una lista de ejercicios de muestra. Al guardar, insertar
/// en `personal_records` (status = pendiente) con el ejercicio elegido.
struct LogPrSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var exercise: String?
    @State private var result = ""
    @State private var date = Date()
    @State private var notes = ""

    // TODO: reemplazar por `exercises` de Supabase (búsqueda + categoría).
    private let exercises = [
        "Back Squat", "Clean & Jerk", "Peso Muerto", "Snatch", "Press Banca",
        "Fran (Time)", "Muscle Ups"
    ]

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

    // MARK: - Ejercicio (picker)

    private var exerciseField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Ejercicio")
            Menu {
                ForEach(exercises, id: \.self) { ex in
                    Button(ex) {
                        Haptics.selection()
                        exercise = ex
                    }
                }
            } label: {
                HStack(spacing: NDCSpacing.stackSM) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NDCColor.outline)
                    Text(exercise ?? "Buscar ejercicio (ej. Back Squat)")
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
            .accessibilityValue(exercise ?? "Sin seleccionar")
        }
    }

    // MARK: - Resultado + Fecha

    private var resultField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Resultado")
            HStack {
                TextField("0.0", text: $result)
                    .keyboardType(.decimalPad)
                    .font(NDCFont.bodyLG)
                Text("KG")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.outline)
            }
            .padding(.horizontal, NDCSpacing.gutter)
            .frame(height: 48)
            .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 4) {
            fieldLabel("Fecha")
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(NDCColor.outline)
                DatePicker("", selection: $date, displayedComponents: .date)
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
            Button(action: save) {
                Label("Guardar Marca", systemImage: "square.and.arrow.down")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
                    .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
            }
            .disabled(exercise == nil || result.isEmpty)
            .opacity(exercise == nil || result.isEmpty ? 0.6 : 1)
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

    private func save() {
        Haptics.notify(.success)
        // TODO: insertar en personal_records (status = pendiente)
        dismiss()
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) { LogPrSheet() }
}
