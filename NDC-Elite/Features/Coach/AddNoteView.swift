import SwiftUI

/// Añadir Nota del Coach — diseño Stitch "Añadir Nota del Coach".
/// Sheet desde el perfil del atleta (vista coach). Categoría · contenido · fecha
/// · visibilidad (solo coach / compartida). (ver FLOWS.md → AddNoteSheet)
///
/// TODO(datos): al guardar, insertar en `coach_notes` (athlete_id, category,
/// content, visibility, note_date).
struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let athleteName: String

    @State private var category: NoteCategory = .general
    @State private var content = ""
    @State private var date = Date()
    @State private var visibility: NoteVisibility = .soloCoach

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
                    Button("Guardar") { save() }
                        .font(NDCFont.labelBold).foregroundStyle(content.isEmpty ? NDCColor.outline : NDCColor.primary)
                        .disabled(content.isEmpty)
                }
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private var athleteHeader: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: nil, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(athleteName).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Text("Atleta RX • Última sesión: Hoy").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
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

    private func save() {
        Haptics.notify(.success)
        // TODO: insertar en coach_notes
        dismiss()
    }
}

#Preview {
    AddNoteView(athleteName: "Marcos Rodríguez")
}
