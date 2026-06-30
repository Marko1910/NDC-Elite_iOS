import SwiftUI

/// Tab 2 · WODs del coach — diseño Stitch "Gestión de WODs".
/// Selector de semana · resumen semanal · lista de WODs por día con estado
/// (publicado/borrador), tipo y acciones (editar/eliminar) · FAB para crear
/// WOD o sesión de running. (ver FLOWS.md → WodManagementView)
///
/// TODO(datos): hoy usa `WodManagementData.sample`. Conectar a Supabase:
/// wods por semana (status, wod_type, time_cap, focus).
struct WodManagementView: View {
    let profile: Profile
    private let data = WodManagementData.sample
    @State private var selectedDay = 0
    @State private var showWodEditor = false
    @State private var showRunningEditor = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    weekSelector
                    weeklySummary
                    dayHeader
                    ForEach(data.wods) { wod in
                        WodManagementRow(wod: wod)
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, 96)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Gestión de WODs")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) { createFAB }
            .navigationDestination(isPresented: $showWodEditor) { WodEditorView() }
            .sheet(isPresented: $showRunningEditor) { RunningEditorView() }
        }
        .tint(NDCColor.primary)
    }

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(Array(data.week.enumerated()), id: \.offset) { index, day in
                    Button {
                        Haptics.selection()
                        selectedDay = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.weekday).font(NDCFont.labelSM)
                            Text(day.number).font(NDCFont.headlineSM)
                        }
                        .foregroundStyle(selectedDay == index ? .white : NDCColor.primary)
                        .frame(width: 52, height: 64)
                        .background(selectedDay == index ? NDCColor.primary : NDCColor.surface,
                                    in: .rect(cornerRadius: NDCRadius.large))
                    }
                    .accessibilityLabel("\(day.weekday) \(day.number)")
                    .accessibilityAddTraits(selectedDay == index ? .isSelected : [])
                }
            }
        }
    }

    private var weeklySummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RESUMEN SEMANAL").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8)).tracking(1)
                Text("\(data.weeklyCount) WODs").font(NDCFont.headlineMD).foregroundStyle(.white)
                Text("Programados para esta semana").font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 28)).foregroundStyle(NDCColor.accent)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.12), in: .rect(cornerRadius: NDCRadius.standard))
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
    }

    private var dayHeader: some View {
        HStack {
            Text("WODs del \(data.week[selectedDay].weekdayLong)")
                .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            Spacer()
            Text("\(data.wods.count) sesiones").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
        }
    }

    private var createFAB: some View {
        Menu {
            Button { Haptics.impact(); showWodEditor = true } label: {
                Label("Nuevo WOD", systemImage: "plus.square.on.square")
            }
            Button { Haptics.impact(); showRunningEditor = true } label: {
                Label("Nueva Sesión de Running", systemImage: "figure.run")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(NDCColor.primary)
                .frame(width: 56, height: 56)
                .background(NDCColor.accent, in: .circle)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.trailing, NDCSpacing.marginMain)
        .padding(.bottom, NDCSpacing.stackLG)
        .accessibilityLabel("Crear WOD o sesión")
    }
}

// MARK: - Fila de WOD (gestión)

private struct WodManagementRow: View {
    let wod: WodManagementData.WodItem

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                Text(wod.status.uppercased())
                    .font(NDCFont.labelSM)
                    .foregroundStyle(wod.isPublished ? .green : NDCColor.outline)
                Spacer()
                HStack(spacing: NDCSpacing.gutter) {
                    Button { Haptics.impact(.light) } label: {
                        Image(systemName: "pencil").foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Editar \(wod.title)")
                    Button { Haptics.impact(.light) } label: {
                        Image(systemName: "trash").foregroundStyle(NDCColor.error)
                    }
                    .accessibilityLabel("Eliminar \(wod.title)")
                }
            }
            Text(wod.title).font(NDCFont.headlineSM).foregroundStyle(NDCColor.onSurface)
            HStack(spacing: NDCSpacing.stackSM) {
                Label(wod.metric, systemImage: wod.icon)
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.onSurfaceVariant)
                NDCChip(text: wod.type)
                NDCChip(text: wod.level, color: NDCColor.onSurfaceVariant)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Datos de muestra

private struct WodManagementData {
    struct Day { let weekday, number, weekdayLong: String }
    struct WodItem: Identifiable {
        let id = UUID()
        let title, status, metric, icon, type, level: String
        var isPublished: Bool { status.lowercased() == "publicado" }
    }

    let week: [Day]
    let weeklyCount: Int
    let wods: [WodItem]

    static let sample = WodManagementData(
        week: [
            Day(weekday: "LUN", number: "24", weekdayLong: "Lunes"),
            Day(weekday: "MAR", number: "25", weekdayLong: "Martes"),
            Day(weekday: "MIÉ", number: "26", weekdayLong: "Miércoles"),
            Day(weekday: "JUE", number: "27", weekdayLong: "Jueves"),
            Day(weekday: "VIE", number: "28", weekdayLong: "Viernes"),
            Day(weekday: "SÁB", number: "29", weekdayLong: "Sábado"),
            Day(weekday: "DOM", number: "30", weekdayLong: "Domingo")
        ],
        weeklyCount: 12,
        wods: [
            WodItem(title: "The Ghost", status: "Publicado", metric: "20' Cap", icon: "timer", type: "AMRAP", level: "RX"),
            WodItem(title: "Murph Prep", status: "Borrador", metric: "45' Duration", icon: "clock", type: "EMOM", level: "Escalado"),
            WodItem(title: "Cisne Negro", status: "Publicado", metric: "AMRAP 15'", icon: "timer", type: "Gymnastics", level: "RX"),
            WodItem(title: "Fondo Dominical", status: "Publicado", metric: "10km Aerobic", icon: "figure.run", type: "Outdoor", level: "Running")
        ]
    )
}

#Preview {
    WodManagementView(profile: .preview)
}
