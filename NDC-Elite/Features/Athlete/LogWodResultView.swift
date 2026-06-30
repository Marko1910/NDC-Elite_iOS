import SwiftUI

/// Registro de resultado de un WOD — diseño Stitch "Registro de Resultados v2".
/// Se presenta **empujada dentro del tab WOD** (la barra de pestañas inferior
/// permanece visible). Header: ✕ · "Registrar Resultado" · Guardar.
/// (ver FLOWS.md → LogWodResultSheet)
///
/// TODO(datos): hoy usa `LogResultData.sample`. Al confirmar, insertar en
/// `wod_results` (status = pendiente) para el WOD seleccionado.
struct LogWodResultView: View {
    @Environment(\.dismiss) private var dismiss
    private let data = LogResultData.sample

    @State private var doneTasks: Set<Int> = [0]
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var weight = ""
    @State private var unit: WeightUnit = .lbs
    @State private var rpe = 7
    @State private var notes = ""

    enum WeightUnit: String, CaseIterable { case lbs = "Lbs", kg = "Kg" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                wodCard
                tasksSection
                metconResultSection
                rpeSection
                notesSection
                confirmButton
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
                Button("Guardar") { save() }
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
        }
    }

    // MARK: - Card del WOD

    private var wodCard: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack(alignment: .top) {
                Text(data.wodTitle)
                    .font(NDCFont.headlineMD)
                    .foregroundStyle(.white)
                Spacer()
                Text(data.rxLevel)
                    .font(NDCFont.labelSM)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.20), in: .capsule)
            }
            Text(data.subtitle)
                .font(NDCFont.labelSM)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Tareas completadas

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Tareas Completadas")
            VStack(spacing: 0) {
                ForEach(Array(data.tasks.enumerated()), id: \.offset) { index, task in
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
                    if index < data.tasks.count - 1 {
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
        Button(action: save) {
            Label("CONFIRMAR RESULTADO", systemImage: "checkmark.circle.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.2), radius: 8, y: 4)
        }
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

    private func save() {
        Haptics.notify(.success)
        // TODO: insertar en wod_results (status = pendiente)
        dismiss()
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

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct LogResultData {
    let wodTitle: String
    let rxLevel: String
    let subtitle: String
    let tasks: [String]

    static var sample: LogResultData {
        LogResultData(
            wodTitle: "El Desafío Híbrido",
            rxLevel: "RX",
            subtitle: "\(Self.todayLabel) • Fuerza & Metcon",
            tasks: [
                "Calentamiento (3 Rondas)",
                "Back Squat (5 Sets de 3 Reps)",
                "Metcon: El Desafío Híbrido"
            ]
        )
    }

    private static var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d 'de' MMMM"
        return "Hoy, \(f.string(from: Date()).capitalized)"
    }
}

#Preview {
    NavigationStack { LogWodResultView() }
}
