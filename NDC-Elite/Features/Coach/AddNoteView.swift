import SwiftUI

/// Añadir Nota del Coach — diseño Stitch "Añadir Nota del Coach".
/// Sheet desde el perfil del atleta (vista coach). Categoría · contenido · fecha
/// · visibilidad (solo coach / compartida). (ver FLOWS.md → AddNoteSheet)
///
/// Al guardar inserta en `coach_notes` (coach_id = usuario autenticado, por RLS).
struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let athlete: Profile

    @State private var category: NoteCategory = .general
    @State private var content = ""
    @State private var date = Date()
    @State private var visibility: NoteVisibility = .soloCoach
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    athleteHeader
                    section("Categoría") { categoryPicker }
                    section("Contenido") { contentEditor }
                    HStack(spacing: NDCSpacing.gutter) {
                        section("Fecha") {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden().tint(NDCColor.primary)
                        }
                        section("Visibilidad") { visibilityToggle }
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
            }
            .background(NDCColor.surface)
            .navigationTitle("Añadir Nota")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Guardando…" : "Guardar") { Task { await save() } }
                        .font(NDCFont.labelBold).foregroundStyle(content.isEmpty ? NDCColor.outline : NDCColor.primary)
                        .disabled(content.isEmpty || isSaving)
                }
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private var athleteHeader: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.fullName).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Text("Atleta \(athlete.level.displayName)").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(NoteCategory.allCases, id: \.self) { cat in
                    Button {
                        Haptics.selection(); category = cat
                    } label: {
                        Text(cat.rawValue.capitalized)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(category == cat ? .white : NDCColor.primary)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(category == cat ? NDCColor.primary : NDCColor.primary.opacity(0.1), in: .capsule)
                    }
                    .accessibilityAddTraits(category == cat ? .isSelected : [])
                }
            }
        }
    }

    private var contentEditor: some View {
        ZStack(alignment: .topLeading) {
            if content.isEmpty {
                Text("Escribe tu observación sobre el atleta...")
                    .font(NDCFont.bodyMD).foregroundStyle(NDCColor.outline)
                    .padding(.horizontal, NDCSpacing.gutter + 4).padding(.vertical, NDCSpacing.gutter)
            }
            TextEditor(text: $content)
                .font(NDCFont.bodyMD).frame(minHeight: 120)
                .scrollContentBackground(.hidden).padding(NDCSpacing.stackSM)
        }
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.25), lineWidth: 1))
    }

    private var visibilityToggle: some View {
        Menu {
            Button("Solo Coach") { visibility = .soloCoach }
            Button("Compartida") { visibility = .compartida }
        } label: {
            HStack {
                Image(systemName: visibility == .soloCoach ? "lock.fill" : "person.2.fill")
                Text(visibility == .soloCoach ? "Solo Coach" : "Compartida")
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
            .padding(.horizontal, NDCSpacing.gutter).frame(height: 44)
            .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() async {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await CoachRepository().addNote(
                athleteId: athlete.id,
                category: category,
                content: trimmed,
                visibility: visibility,
                noteDate: date
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la nota. Revisa tu conexión e inténtalo de nuevo."
        }
    }
}

#Preview {
    AddNoteView(athlete: .preview)
}
