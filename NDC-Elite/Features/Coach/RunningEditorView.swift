import SwiftUI

/// Nueva Sesión de Running (coach) — diseño Stitch "Nuevo Registro de Running".
/// Sheet desde el FAB de Gestión de WODs. Fecha · hora de salida · nombre de
/// ruta · distancia objetivo · ruta/mapa · notas. Publicar sesión.
/// (ver FLOWS.md → RunningEditorSheet)
///
/// TODO(datos): al publicar, insertar en wods (wod_type=running, distance_km,
/// pace_target, route_url, is_outdoor=true).
struct RunningEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var date = Date()
    @State private var startTime = Date()
    @State private var routeName = ""
    @State private var distance = ""
    @State private var notes = ""

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
                    field("Distancia Objetivo (KM)") {
                        HStack { TextField("10", text: $distance).keyboardType(.decimalPad); Text("KM").foregroundStyle(NDCColor.outline) }
                    }

                    VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                        Text("RUTA Y UBICACIÓN").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                        Button {
                            Haptics.impact(.light)
                            // TODO: marcar ruta en el mapa (MapKit)
                        } label: {
                            ZStack {
                                LinearGradient(colors: [NDCColor.primary.opacity(0.15), NDCColor.surface], startPoint: .top, endPoint: .bottom)
                                VStack(spacing: NDCSpacing.stackSM) {
                                    Image(systemName: "mappin.and.ellipse").font(.system(size: 28)).foregroundStyle(NDCColor.primary)
                                    Text("Marcar Ruta en el Mapa").font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                                }
                            }
                            .frame(height: 120)
                            .clipShape(.rect(cornerRadius: NDCRadius.large))
                        }
                    }
                    field("Notas Adicionales") { TextField("Ritmo objetivo, hidratación...", text: $notes) }
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
                    Button("Guardar") { save() }.font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: save) {
                    Label("Publicar Sesión", systemImage: "checkmark.circle.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
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

    private func save() {
        Haptics.notify(.success)
        dismiss()
    }
}

#Preview {
    RunningEditorView()
}
