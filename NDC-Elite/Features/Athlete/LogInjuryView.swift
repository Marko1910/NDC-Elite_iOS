import SwiftUI

/// Registrar Nueva Lesión — diseño Stitch "Registrar Nueva Lesión".
/// Empujada dentro del tab Perfil (conserva el navbar). Header ✕ · título ·
/// Guardar. Zona del cuerpo (grid) · nivel de dolor · descripción · fecha.
/// (ver FLOWS.md → LogInjurySheet)
///
/// Al guardar inserta en `injuries` (reported_by = atleta, status = activa).
struct LogInjuryView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var zone: BodyZone?
    @State private var severity: InjurySeverity = .leve
    @State private var detail = ""
    @State private var incidentDate = Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                bodyZoneSection
                painLevelSection
                descriptionSection
                dateSection
                if let errorMessage {
                    Text(errorMessage)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.error)
                }
                saveButton
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Nueva Lesión")
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
                    .foregroundStyle(zone == nil ? NDCColor.outline : NDCColor.primary)
                    .disabled(zone == nil || isSaving)
            }
        }
    }

    // MARK: - Zona del cuerpo

    private var bodyZoneSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Zona del Cuerpo")
            LazyVGrid(columns: columns, spacing: NDCSpacing.gutter) {
                ForEach(BodyZone.allCases, id: \.self) { z in
                    Button {
                        Haptics.selection()
                        zone = z
                    } label: {
                        VStack(spacing: NDCSpacing.stackSM) {
                            Image(systemName: z.symbol)
                                .font(.system(size: 24))
                            Text(z.displayName)
                                .font(NDCFont.labelSM)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .foregroundStyle(zone == z ? .white : NDCColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NDCSpacing.gutter)
                        .background(zone == z ? NDCColor.primary : NDCColor.surface,
                                    in: .rect(cornerRadius: NDCRadius.large))
                    }
                    .accessibilityLabel(z.displayName)
                    .accessibilityAddTraits(zone == z ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Nivel de dolor

    private var painLevelSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Nivel de Dolor")
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(InjurySeverity.allCases, id: \.self) { level in
                    Button {
                        Haptics.selection()
                        severity = level
                    } label: {
                        Text(level.rawValue.capitalized)
                            .font(NDCFont.bodyLG.weight(.semibold))
                            .foregroundStyle(severity == level ? .white : NDCColor.onSurface)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(severity == level ? NDCColor.primary : NDCColor.surface,
                                        in: .rect(cornerRadius: NDCRadius.standard))
                    }
                    .accessibilityAddTraits(severity == level ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Descripción

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Descripción")
            ZStack(alignment: .topLeading) {
                if detail.isEmpty {
                    Text("Ej: Pinchazo al hacer sentadilla profunda...")
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.outline)
                        .padding(.horizontal, NDCSpacing.gutter + 4)
                        .padding(.vertical, NDCSpacing.gutter)
                }
                TextEditor(text: $detail)
                    .font(NDCFont.bodyMD)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(NDCSpacing.stackSM)
            }
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    // MARK: - Fecha del incidente

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            sectionHeader("Fecha del Incidente")
            HStack {
                Image(systemName: "calendar").foregroundStyle(NDCColor.outline)
                DatePicker("", selection: $incidentDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(NDCColor.primary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, NDCSpacing.gutter)
            .frame(height: 52)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    // MARK: - Guardar

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            Text(isSaving ? "Guardando…" : "Guardar Registro")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.2), radius: 8, y: 4)
        }
        .disabled(zone == nil || isSaving)
        .opacity(zone == nil ? 0.6 : 1)
        .padding(.top, NDCSpacing.stackSM)
        .accessibilityHint("Guarda la lesión en tu historial médico")
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.outline)
    }

    private func save() async {
        guard let zone, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let trimmed = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await AthleteRepository().logInjury(
                bodyZone: zone,
                severity: severity,
                description: trimmed.isEmpty ? nil : trimmed,
                incidentDate: incidentDate
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la lesión. Revisa tu conexión e inténtalo de nuevo."
        }
    }
}

// MARK: - Icono por zona del cuerpo

extension BodyZone {
    var symbol: String {
        switch self {
        case .cabeza: "brain.head.profile"
        case .hombros: "figure.arms.open"
        case .espalda: "figure.stand"
        case .codos: "figure.flexibility"
        case .munecas: "hand.raised.fill"
        case .lumbar: "figure.walk"
        case .cadera: "figure.walk.motion"
        case .rodillas: "figure.run"
        case .tobillos: "shoeprints.fill"
        }
    }
}

#Preview {
    NavigationStack { LogInjuryView() }
}
