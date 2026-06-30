import SwiftUI

/// Editor de WOD (coach) — diseño Stitch "Editor de WOD - Flujo de Ejercicios".
/// Crea/edita el WOD del día: fecha, nombre, tipo, time cap, y bloques con sus
/// ejercicios (añadir desde biblioteca). Publicar o guardar borrador.
/// (ver FLOWS.md → WodEditorView)
///
/// TODO(datos): al publicar/guardar, insertar/actualizar wods + wod_blocks +
/// wod_block_exercises. "Añadir Ejercicio" abre la biblioteca (ExercisePickerSheet).
struct WodEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var name = ""
    @State private var type: WodType = .amrap
    @State private var timeCap = ""
    @State private var blocks = WodEditorData.sampleBlocks

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                Text("Nuevo WOD del Día").font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)

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
                ForEach(blocks) { block in
                    BlockEditor(block: block)
                }
            }
            .padding(NDCSpacing.marginMain)
            .padding(.bottom, 100)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Creador de Entrenamientos")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: NDCSpacing.stackMD) {
                Button {
                    Haptics.impact(); dismiss()
                } label: {
                    Text("Guardar Borrador").font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.primary, lineWidth: 1))
                }
                Button {
                    Haptics.notify(.success); dismiss()
                } label: {
                    Label("Publicar", systemImage: "checkmark.circle.fill").font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackSM)
            .background(.ultraThinMaterial)
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
}

private struct BlockEditor: View {
    let block: WodEditorData.Block

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label(block.title, systemImage: block.icon)
                .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
            ForEach(block.exercises, id: \.self) { ex in
                HStack {
                    Image(systemName: "line.3.horizontal").foregroundStyle(NDCColor.outline)
                    Text(ex).font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                    Spacer()
                    Image(systemName: "eye").foregroundStyle(NDCColor.primary)
                }
                .padding(.vertical, 6)
            }
            Button {
                Haptics.impact(.light)
                // TODO: → ExercisePickerSheet (biblioteca)
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

private enum WodEditorData {
    struct Block: Identifiable { let id = UUID(); let title, icon: String; let exercises: [String] }
    static let sampleBlocks: [Block] = [
        Block(title: "Calentamiento", icon: "leaf.fill", exercises: ["200m Run", "10 Scapular Pull-ups", "15 Air Squats"]),
        Block(title: "Técnica / Fuerza", icon: "dumbbell.fill", exercises: ["Back Squat — 5 sets de 5 al 75% 1RM"]),
        Block(title: "Metcon RX", icon: "timer", exercises: ["Chest to Bar Pull-ups — 5 Reps", "Power Snatches — 15 Reps (75/55 lb)"])
    ]
}

#Preview {
    NavigationStack { WodEditorView() }
}
