import SwiftUI

/// Nueva Sesión de Running (coach) — diseño Stitch "Nuevo Registro de Running".
/// Sheet desde el FAB de Gestión de WODs. Fecha · hora de salida · nombre de
/// ruta · distancia objetivo · ruta/mapa · notas. Publicar sesión.
/// (ver FLOWS.md → RunningEditorSheet)
///
/// Al publicar inserta en `wods` (wod_type = running, status = publicado,
/// distance_km, is_outdoor = true; la hora de salida viaja en `focus`).
struct RunningEditorView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var startTime = Date()
    @State private var routeName = ""
    @State private var distance = ""
    @State private var paceTarget = ""
    @State private var routeURL = ""
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    private var canPublish: Bool {
        !routeName.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Label("Planificación de Coach", systemImage: "figure.run")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    Text("Detalles del Desafío").font(NDCFont.headlineSM).foregroundStyle(NDCColor.onSurface)

                    HStack(spacing: NDCSpacing.gutter) {
                        field("Fecha de la Sesión") {
                            DatePicker("", selection: $date, displayedComponents: .date).labelsHidden().tint(NDCColor.primary)
                        }
                        field("Hora de Salida") {
                            DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute).labelsHidden().tint(NDCColor.primary)
                        }
                    }
                    field("Nombre de la Ruta/Desafío") { TextField("Ej: Fondo Dominical", text: $routeName) }
                    HStack(alignment: .top, spacing: NDCSpacing.gutter) {
                        field("Distancia (KM)") {
                            HStack { TextField("10", text: $distance).keyboardType(.decimalPad); Text("KM").foregroundStyle(NDCColor.outline) }
                        }
                        field("Ritmo Objetivo") {
                            HStack { TextField("5:30", text: $paceTarget); Text("MIN/KM").foregroundStyle(NDCColor.outline) }
                        }
                    }
                    field("Enlace de la Ruta (opcional)") {
                        TextField("Strava, Google Maps...", text: $routeURL)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    field("Notas Adicionales") { TextField("Hidratación, punto de encuentro...", text: $notes) }
                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
                .padding(.bottom, 80)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Nueva Sesión de Running")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { dismiss() } label: { Image(systemName: "xmark") } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Guardando…" : "Guardar") { Task { await save() } }
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        .disabled(!canPublish)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await save() }
                } label: {
                    Label(isSaving ? "Publicando…" : "Publicar Sesión", systemImage: "checkmark.circle.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
                .disabled(!canPublish)
                .opacity(canPublish || isSaving ? 1 : 0.5)
                .padding(.horizontal, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackSM)
                .background(.ultraThinMaterial)
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG).padding(NDCSpacing.gutter).frame(maxWidth: .infinity, alignment: .leading)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() async {
        guard canPublish else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPace = paceTarget.trimmingCharacters(in: .whitespaces)
        let trimmedURL = routeURL.trimmingCharacters(in: .whitespaces)
        do {
            try await WodRepository().publishRunning(
                title: routeName.trimmingCharacters(in: .whitespaces),
                scheduledDate: date,
                startLabel: startTime.formatted(date: .omitted, time: .shortened),
                distanceKm: Double(distance.replacingOccurrences(of: ",", with: ".")),
                paceTarget: trimmedPace.isEmpty ? nil : "\(trimmedPace) min/km",
                routeURL: trimmedURL.isEmpty ? nil : trimmedURL,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
                createdBy: profile.id
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo publicar la sesión. Revisa tu conexión e inténtalo de nuevo."
        }
    }
}

#Preview {
    RunningEditorView(profile: .preview)
}
