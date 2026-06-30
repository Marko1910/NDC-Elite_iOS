import SwiftUI

/// Tab 3 · Progreso del atleta — diseño Stitch "Rendimiento y Ranking Unificado".
/// Sirve para revisar los PR por ejercicio y la progresión general.
/// Header del atleta · hero de rendimiento · Recientes (último logro) ·
/// Marcas Clave (PR por ejercicio) · FAB registrar PR.
/// (ver FLOWS.md → PerformanceView)
///
/// Decisión de diseño: añadimos un acceso a la **Biblioteca Técnica** en la
/// barra superior (junto a la campana) — acción de consulta, no compite con el
/// FAB (acción primaria: registrar PR). Lleva a `ExerciseLibraryView` (07).
///
/// TODO(datos): hoy usa `PerformanceData.sample`. Conectar a Supabase:
/// personal_records (conteo + recientes + por ejercicio), profiles (membresía).
struct PerformanceView: View {
    let profile: Profile
    private let data = PerformanceData.sample

    @State private var showLogPr = false
    @State private var showPrDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    athleteHeader
                    Text("Rendimiento y Ranking")
                        .font(NDCFont.displayLG)
                        .foregroundStyle(NDCColor.primaryDark)
                    PerformanceHeroCard(state: data.state)
                    recientesSection
                    marcasClaveSection
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, 96) // espacio para el FAB
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottomTrailing) { logPrFAB }
            .sheet(isPresented: $showLogPr) { LogPrSheet() }
            .navigationDestination(isPresented: $showPrDetail) { PrDetailView() }
            .toolbar(.hidden, for: .navigationBar)
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Header del atleta (avatar + nombre · biblioteca + campana)

    private var athleteHeader: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            NDCAvatarView(urlString: profile.avatarURL, size: 40)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(profile.fullName)
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
                Text(data.membership)
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.onSurfaceVariant)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            Button {
                Haptics.impact(.light)
                // TODO: → ExerciseLibraryView (Biblioteca Técnica)
            } label: {
                Image(systemName: "books.vertical")
                    .font(.system(size: 20))
                    .foregroundStyle(NDCColor.primary)
                    .frame(width: 40, height: 40)
            }
            .accessibilityLabel("Biblioteca de técnica")
        }
    }

    // MARK: - Recientes

    private var recientesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            sectionHeader("Recientes", action: "Ver todo") {
                // TODO: → PrHistoryList
            }
            Button {
                Haptics.impact(.light)
                showPrDetail = true
            } label: {
                HStack(spacing: NDCSpacing.gutter) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(NDCColor.secondary)
                        .frame(width: 56, height: 56)
                        .background(NDCColor.accent.opacity(0.20), in: .rect(cornerRadius: NDCRadius.standard))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ÚLTIMO LOGRO")
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.onSurfaceVariant)
                        Text(data.recent.exercise)
                            .font(NDCFont.headlineSM)
                            .foregroundStyle(NDCColor.primary)
                        HStack(spacing: 4) {
                            Text(data.recent.value)
                                .font(NDCFont.bodyLG.weight(.bold))
                                .foregroundStyle(NDCColor.primary)
                            Text(data.recent.delta)
                                .font(NDCFont.bodyMD)
                                .foregroundStyle(NDCColor.error)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: NDCRadius.large)
                        .stroke(NDCColor.outline.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: NDCColor.primaryDark.opacity(0.06), radius: 6, y: 2)
            }
            .accessibilityLabel("Último logro: \(data.recent.exercise), \(data.recent.value), \(data.recent.delta)")
        }
    }

    // MARK: - Marcas Clave (PR por ejercicio)

    private var marcasClaveSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Marcas Clave")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
            VStack(spacing: NDCSpacing.stackMD) {
                ForEach(data.keyMarks) { mark in
                    KeyMarkRow(mark: mark) {
                        Haptics.impact(.light)
                        showPrDetail = true
                    }
                }
            }
        }
    }

    // MARK: - FAB registrar PR

    private var logPrFAB: some View {
        Button {
            Haptics.impact()
            showLogPr = true
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
        .accessibilityLabel("Registrar nueva marca")
    }

    // MARK: - Helper de encabezado de sección con acción

    private func sectionHeader(_ title: String, action: String, perform: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
            Spacer()
            Button(action) {
                Haptics.impact(.light)
                perform()
            }
            .font(NDCFont.labelBold)
            .foregroundStyle(NDCColor.primary)
        }
    }
}

// MARK: - Hero "Estado de Rendimiento"

private struct PerformanceHeroCard: View {
    let state: PerformanceData.State

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(alignment: .top) {
                Text("ESTADO DE RENDIMIENTO")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(.white.opacity(0.8))
                    .tracking(1)
                Spacer()
                Label("ACTIVO", systemImage: "bolt.fill")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Rendimiento Total")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(.white.opacity(0.9))
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(state.totalPRs) PRs")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(.white)
                    Text(state.deltaPercent)
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.accent)
                }
                Text("este año vs. periodo anterior")
                    .font(NDCFont.bodyMD)
                    .foregroundStyle(.white.opacity(0.7))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.20))
                    Capsule().fill(NDCColor.accent)
                        .frame(width: geo.size.width * state.progress)
                }
            }
            .frame(height: 4)
            .padding(.top, NDCSpacing.stackSM)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estado de rendimiento, activo. \(state.totalPRs) PRs, \(state.deltaPercent) este año vs. periodo anterior")
    }
}

// MARK: - Fila de PR por ejercicio

private struct KeyMarkRow: View {
    let mark: PerformanceData.KeyMark
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                HStack(spacing: NDCSpacing.stackMD) {
                    Image(systemName: mark.icon)
                        .foregroundStyle(NDCColor.primary)
                    Text(mark.name)
                        .font(NDCFont.bodyLG.weight(.semibold))
                        .foregroundStyle(NDCColor.onSurface)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(mark.value)
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.primary)
                    Text(mark.tag)
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
            }
            .padding(NDCSpacing.gutter)
            .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mark.name): \(mark.value), \(mark.tag)")
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct PerformanceData {
    struct State {
        let totalPRs: Int
        let deltaPercent: String
        let progress: Double
    }
    struct Recent {
        let exercise: String
        let value: String
        let delta: String
    }
    struct KeyMark: Identifiable {
        let id = UUID()
        let icon: String
        let name: String
        let value: String
        let tag: String
    }

    let membership: String
    let state: State
    let recent: Recent
    let keyMarks: [KeyMark]

    static let sample = PerformanceData(
        membership: "Elite Member",
        state: State(totalPRs: 24, deltaPercent: "+12%", progress: 0.75),
        recent: Recent(exercise: "Sentadilla Trasera", value: "145kg", delta: "+5kg"),
        keyMarks: [
            KeyMark(icon: "figure.gymnastics", name: "Muscle Ups", value: "12 Reps", tag: "RX"),
            KeyMark(icon: "timer", name: "Fran", value: "3:12", tag: "Benchmark"),
            KeyMark(icon: "scalemass.fill", name: "Peso Muerto", value: "180kg", tag: "Máximo")
        ]
    )
}

#Preview {
    PerformanceView(profile: .preview)
}
