import SwiftUI

/// Historial de WODs del atleta — pantalla nueva (no existe en Stitch; diseñada
/// coherente con el design system NDC HQ). Lista los WODs pasados con el
/// resultado registrado por el atleta y su estado de validación. Se accede
/// desde el icono de historial del tab WOD.
///
/// TODO(datos): usa `WodHistoryData.sample`. Conectar a Supabase: wods (pasados)
/// + wod_results del atleta (tiempo/rounds/reps, status, is_pr).
struct WodHistoryView: View {
    private let data = WodHistoryData.sample
    @State private var filter: Filter = .todos

    enum Filter: String, CaseIterable { case todos = "Todos", registrados = "Registrados", pendientes = "Pendientes" }

    private var filtered: [WodHistoryData.Entry] {
        switch filter {
        case .todos: data.entries
        case .registrados: data.entries.filter { $0.result != nil }
        case .pendientes: data.entries.filter { $0.result == nil }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                summaryCard
                filterChips
                if filtered.isEmpty {
                    ContentUnavailableView("Sin WODs", systemImage: "calendar.badge.exclamationmark",
                                           description: Text("No hay entrenamientos en esta categoría."))
                        .padding(.top, NDCSpacing.stackLG)
                } else {
                    ForEach(filtered) { entry in
                        WodHistoryRow(entry: entry)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Historial de WODs")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Resumen

    private var summaryCard: some View {
        HStack(spacing: NDCSpacing.gutter) {
            summaryStat(value: "\(data.totalCompleted)", label: "Completados")
            Divider().frame(height: 40).overlay(.white.opacity(0.2))
            summaryStat(value: "\(data.prCount)", label: "PRs")
            Divider().frame(height: 40).overlay(.white.opacity(0.2))
            summaryStat(value: data.compliance, label: "Racha")
        }
        .frame(maxWidth: .infinity)
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.totalCompleted) WODs completados, \(data.prCount) PRs, racha \(data.compliance)")
    }

    private func summaryStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(NDCFont.headlineMD).foregroundStyle(.white)
            Text(label).font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Filtro

    private var filterChips: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            ForEach(Filter.allCases, id: \.self) { f in
                Button {
                    Haptics.selection()
                    withAnimation(.snappy) { filter = f }
                } label: {
                    Text(f.rawValue)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(filter == f ? .white : NDCColor.primary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(filter == f ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
                }
                .accessibilityAddTraits(filter == f ? .isSelected : [])
            }
            Spacer()
        }
    }
}

// MARK: - Fila del historial

private struct WodHistoryRow: View {
    let entry: WodHistoryData.Entry

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            // Fecha (día + mes)
            VStack(spacing: 0) {
                Text(entry.day).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                Text(entry.month.uppercased()).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            .frame(width: 48)

            Rectangle().fill(NDCColor.outline.opacity(0.2)).frame(width: 1, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: NDCSpacing.stackSM) {
                    NDCChip(text: entry.type)
                    if entry.isPr {
                        Label("PR", systemImage: "star.fill")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onAccent)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(NDCColor.accent, in: .capsule)
                    }
                }
                Text(entry.title).font(NDCFont.bodyLG.weight(.semibold)).foregroundStyle(NDCColor.onSurface)
                if let result = entry.result {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(entry.validated ? .green : NDCColor.outline)
                        Text(result).font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        Text(entry.validated ? "· Validado" : "· Pendiente")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                } else {
                    Text("Sin resultado registrado")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large)
            .stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11yLabel)
    }

    private var a11yLabel: String {
        var s = "\(entry.day) de \(entry.month), \(entry.title), \(entry.type)"
        if let r = entry.result { s += ", resultado \(r), \(entry.validated ? "validado" : "pendiente")" }
        else { s += ", sin resultado" }
        if entry.isPr { s += ", récord personal" }
        return s
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct WodHistoryData {
    struct Entry: Identifiable {
        let id = UUID()
        let day: String
        let month: String
        let title: String
        let type: String
        let result: String?
        let validated: Bool
        let isPr: Bool
    }

    let totalCompleted: Int
    let prCount: Int
    let compliance: String
    let entries: [Entry]

    static let sample = WodHistoryData(
        totalCompleted: 48,
        prCount: 5,
        compliance: "85%",
        entries: [
            Entry(day: "29", month: "Jun", title: "El Desafío Híbrido", type: "FOR TIME", result: "12:45", validated: true, isPr: false),
            Entry(day: "27", month: "Jun", title: "Fran", type: "FOR TIME", result: "3:12", validated: true, isPr: true),
            Entry(day: "25", month: "Jun", title: "EMOM 20 — Clean & Jerk", type: "EMOM", result: "85 kg", validated: false, isPr: false),
            Entry(day: "23", month: "Jun", title: "Helen", type: "FOR TIME", result: "10:30", validated: true, isPr: false),
            Entry(day: "20", month: "Jun", title: "AMRAP 15 — Cindy", type: "AMRAP", result: nil, validated: false, isPr: false),
            Entry(day: "18", month: "Jun", title: "Back Squat 5x5", type: "FUERZA", result: "145 kg", validated: true, isPr: true)
        ]
    )
}

#Preview {
    NavigationStack { WodHistoryView() }
}
