import SwiftUI

/// Tab 2 · WOD del atleta — diseño Stitch "WOD Detallado (técnica por ejercicio)".
/// Búsqueda de técnica · héroe (fecha/título/chips) · bloques (calentamiento,
/// fuerza/técnica, metcon) con "ojo" para ver técnica · CTA registrar resultado.
/// (ver FLOWS.md → WodDetailView)
///
/// TODO(datos): hoy usa `WodDetailData.sample`. Conectar a Supabase:
/// wods + wod_blocks + wod_block_exercises (del WOD del día / seleccionado).
struct WodDetailView: View {
    let profile: Profile
    private let data = WodDetailData.sample

    @State private var search = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    searchField
                    hero
                    ForEach(data.blocks) { block in
                        WodBlockCard(block: block, onTechnique: { _ in
                            Haptics.impact(.light)
                            // TODO: → ExerciseDetailView
                        })
                    }
                    registerCTA
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .ndcBrandToolbar(profile: profile, unreadCount: data.unreadCount) {
                // TODO: → AthleteNotificationsView
            }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Búsqueda de técnica

    private var searchField: some View {
        HStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(NDCColor.outline)
            TextField("Buscar técnica de movimientos", text: $search)
                .font(NDCFont.bodyMD)
                .submitLabel(.search)
                .onSubmit { /* TODO: → ExerciseLibraryView con filtro */ }
            if !search.isEmpty {
                Button("Ir") {
                    Haptics.impact(.light)
                    // TODO: → ExerciseLibraryView
                }
                .font(NDCFont.labelBold)
                .foregroundStyle(NDCColor.primary)
            }
        }
        .padding(.horizontal, NDCSpacing.gutter)
        .padding(.vertical, 12)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.outline.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Héroe (fecha + título + chips)

    private var hero: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(data.dateLabel.uppercased())
                .font(NDCFont.labelBold)
                .foregroundStyle(NDCColor.outline)
                .tracking(0.5)
            Text(data.title)
                .font(NDCFont.displayLG)
                .foregroundStyle(NDCColor.primaryDark)
            HStack(spacing: NDCSpacing.stackSM) {
                NDCChip(text: data.rxLevel)
                NDCChip(text: data.focus, color: NDCColor.onSurfaceVariant)
            }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - CTA registrar resultado

    private var registerCTA: some View {
        VStack(spacing: NDCSpacing.stackMD) {
            Button {
                Haptics.impact()
                // TODO: → LogWodResultSheet
            } label: {
                Label("Registrar mi Resultado", systemImage: "square.and.pencil")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(NDCColor.secondary, in: .rect(cornerRadius: NDCRadius.large))
                    .shadow(color: NDCColor.secondary.opacity(0.25), radius: 8, y: 4)
            }
            .accessibilityHint("Registra tu tiempo o marca en este WOD")

            if let count = data.registeredCount {
                Label("\(count) atletas ya registraron su tiempo hoy", systemImage: "person.2.fill")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
            }
        }
        .padding(.top, NDCSpacing.stackSM)
    }
}

// MARK: - Tarjeta de bloque (calentamiento / fuerza / metcon)

private struct WodBlockCard: View {
    let block: WodDetailData.Block
    let onTechnique: (WodDetailData.Movement) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            header
            if let scheme = block.scheme {
                Text(scheme)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
            VStack(spacing: 0) {
                ForEach(Array(block.movements.enumerated()), id: \.element.id) { index, mov in
                    MovementRow(movement: mov, showDivider: index < block.movements.count - 1) {
                        onTechnique(mov)
                    }
                }
            }
            if let cue = block.coachCue {
                coachCueBox(cue)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(block.emphasized ? NDCColor.primary : NDCColor.outline.opacity(0.25),
                        lineWidth: block.emphasized ? 2 : 1)
        )
        .shadow(color: NDCColor.primaryDark.opacity(0.08), radius: 12, y: 4)
    }

    private var header: some View {
        HStack(alignment: .top) {
            HStack(spacing: NDCSpacing.stackSM) {
                Image(systemName: block.icon)
                    .foregroundStyle(block.emphasized ? NDCColor.secondary : NDCColor.primary)
                Text(block.title)
                    .font(block.emphasized ? NDCFont.headlineMD : NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
            }
            Spacer()
            if let trailing = block.trailingLabel {
                if block.emphasized {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Tiempo Límite")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.outline)
                        Text(trailing)
                            .font(NDCFont.headlineSM)
                            .foregroundStyle(NDCColor.primary)
                    }
                } else {
                    Text(trailing)
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.outline)
                }
            }
        }
        .overlay(alignment: .bottomLeading) {
            if let badge = block.badge {
                Text(badge)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
                    .offset(y: 26)
            }
        }
    }

    private func coachCueBox(_ cue: String) -> some View {
        HStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(NDCColor.secondary)
            Text(cue)
                .font(NDCFont.labelSM)
                .italic()
                .foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .padding(NDCSpacing.stackMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
    }
}

// MARK: - Fila de movimiento (con "ojo" de técnica)

private struct MovementRow: View {
    let movement: WodDetailData.Movement
    let showDivider: Bool
    let onTechnique: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(movement.name)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.onSurface)
                    if let detail = movement.detail {
                        Text(detail)
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onSurfaceVariant)
                    }
                }
                Spacer()
                if movement.hasTechnique {
                    Button(action: onTechnique) {
                        Image(systemName: "eye")
                            .font(.system(size: 20))
                            .foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Ver técnica de \(movement.name)")
                }
            }
            .padding(.vertical, NDCSpacing.stackMD)
            if showDivider {
                Divider().overlay(NDCColor.outline.opacity(0.25))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct WodDetailData {
    struct Movement: Identifiable {
        let id = UUID()
        let name: String
        var detail: String? = nil
        var hasTechnique: Bool = true
    }
    struct Block: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        var scheme: String? = nil
        var trailingLabel: String? = nil
        var badge: String? = nil
        var coachCue: String? = nil
        var emphasized: Bool = false
        let movements: [Movement]
    }

    let dateLabel: String
    let title: String
    let rxLevel: String
    let focus: String
    let blocks: [Block]
    let registeredCount: Int?
    let unreadCount: Int

    static var sample: WodDetailData {
        WodDetailData(
            dateLabel: todayLabel,
            title: "El Desafío Híbrido",
            rxLevel: "RX",
            focus: "Fuerza & Metcon",
            blocks: [
                Block(
                    icon: "leaf.fill",
                    title: "Calentamiento",
                    scheme: "3 Rondas de:",
                    trailingLabel: "12 Minutos",
                    movements: [
                        Movement(name: "200m Trote suave"),
                        Movement(name: "15 Air Squats", detail: "Controlados"),
                        Movement(name: "10 Scapular Pull-ups")
                    ]
                ),
                Block(
                    icon: "dumbbell.fill",
                    title: "Fuerza / Técnica",
                    coachCue: "Enfócate en la estabilidad del core durante la pausa.",
                    movements: [
                        Movement(name: "Back Squat (Tempo)",
                                 detail: "5 Sets de 3 Reps al 75% RM. Tempo 3-2-X-1")
                    ]
                ),
                Block(
                    icon: "timer",
                    title: "Metcon",
                    trailingLabel: "20:00",
                    badge: "POR TIEMPO",
                    emphasized: true,
                    movements: [
                        Movement(name: "50 Saltos Dobles", detail: "Saltos dobles de comba"),
                        Movement(name: "40 Lanzamientos de Balón", detail: "Balón 20/14 lbs"),
                        Movement(name: "30 Cargadas de Potencia", detail: "Barra 135/95 lbs"),
                        Movement(name: "20 Burpees sobre la Barra", detail: "Salto lateral")
                    ]
                )
            ],
            registeredCount: 14,
            unreadCount: 2
        )
    }

    /// "Hoy, sábado, 23 de mayo" con la fecha actual en español.
    private static var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE, d 'de' MMMM"
        return "Hoy, \(f.string(from: Date()))"
    }
}

#Preview {
    WodDetailView(profile: .preview)
}
