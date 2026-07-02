import SwiftUI
import Charts

/// Tab 5 · Progreso del coach — diseño Stitch "Rendimiento de Atletas - Coach".
/// Resumen semanal (PRs globales, cumplimiento) · tasa de adherencia (gráfico) ·
/// PRs recientes · atletas más mejorados. (ver FLOWS.md → CommunityProgressView)
///
/// TODO(datos): hoy usa `CommunityProgressData.sample`. Conectar a Supabase:
/// personal_records (PRs globales/recientes), attendance (adherencia), agregados.
struct CommunityProgressView: View {
    let profile: Profile
    private typealias data = CommunityProgressData
    @State private var adherenceStore = CommunityAdherenceStore()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Text("Resumen Semanal").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                    summaryRow
                    adherenceCard
                    recentPRsSection
                    mostImprovedSection
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Progreso Comunitario")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CoachPrsView()
                    } label: {
                        Image(systemName: "trophy")
                    }
                    .accessibilityLabel("PRs de todos los atletas")
                }
            }
            .task { await adherenceStore.load() }
            .refreshable { await adherenceStore.load() }
        }
        .tint(NDCColor.primary)
    }

    private var summaryRow: some View {
        HStack(spacing: NDCSpacing.gutter) {
            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Text("PRs GLOBALES").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Text("\(data.globalPRs)").font(NDCFont.statsXL).foregroundStyle(NDCColor.primaryDark)
                Label("\(data.prDelta) vs ayer", systemImage: "arrow.up.right")
                    .font(NDCFont.labelSM).foregroundStyle(.green)
            }
            .padding(NDCSpacing.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))

            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Text("CUMPLIMIENTO").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Text("\(data.compliance)%").font(NDCFont.statsXL).foregroundStyle(NDCColor.onAccent)
                ProgressView(value: Double(data.compliance) / 100).tint(NDCColor.accent)
            }
            .padding(NDCSpacing.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private var adherenceCard: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Tasa de Adherencia").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Text("Últimos 7 días").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            LoadStateView(
                state: adherenceStore.state,
                retry: { Task { await adherenceStore.load() } }
            ) { days in
                if days.isEmpty {
                    ContentUnavailableView(
                        "Sin atletas activos",
                        systemImage: "person.3",
                        description: Text("Aún no hay atletas activos para calcular adherencia.")
                    )
                } else {
                    Chart(days) { day in
                        BarMark(x: .value("Día", day.label), y: .value("%", day.value))
                            .foregroundStyle(day.value >= 80 ? NDCColor.primary : NDCColor.primary.opacity(0.45))
                            .cornerRadius(4)
                            .annotation(position: .top) {
                                Text("\(day.value)%").font(.system(size: 9)).foregroundStyle(NDCColor.outline)
                            }
                    }
                    .chartYAxis(.hidden)
                    .chartYScale(domain: 0...110)
                    .chartXAxis { AxisMarks { _ in AxisValueLabel().font(NDCFont.labelSM) } }
                    .frame(height: 140)
                }
            } skeleton: {
                SkeletonCard(lines: 1, height: 140)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }

    private var recentPRsSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("PRs Recientes").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                NavigationLink {
                    CoachPrsView()
                } label: {
                    Label("Ver todo", systemImage: "chevron.right")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.primary)
                }
            }
            ForEach(data.recentPRs) { pr in
                HStack(spacing: NDCSpacing.gutter) {
                    NDCAvatarView(urlString: nil, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pr.athlete).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                        Text(pr.exercise).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(pr.value).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                        Text(pr.tag).font(NDCFont.labelSM)
                            .foregroundStyle(pr.isRecord ? .green : NDCColor.onAccent)
                    }
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var mostImprovedSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Atletas Más Mejorados").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            ForEach(Array(data.mostImproved.enumerated()), id: \.element.id) { index, athlete in
                HStack(spacing: NDCSpacing.gutter) {
                    Text(String(format: "%02d", index + 1))
                        .font(NDCFont.headlineSM).foregroundStyle(NDCColor.outline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(athlete.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                        Text("Consistencia: \(athlete.consistency)%").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(athlete.delta).font(NDCFont.headlineSM).foregroundStyle(.green)
                        Text("Progreso mensual").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                .accessibilityElement(children: .combine)
            }
        }
    }
}

// MARK: - Datos de muestra

private enum CommunityProgressData {
    struct Day: Identifiable { let id = UUID(); let label: String; let value: Int }
    struct PR: Identifiable { let id = UUID(); let athlete, exercise, value, tag: String; let isRecord: Bool }
    struct Improved: Identifiable { let id = UUID(); let name: String; let consistency: Int; let delta: String }

    static let globalPRs = 128
    static let prDelta = "+12%"
    static let compliance = 84
    static let recentPRs: [PR] = [
        .init(athlete: "Elena Mora", exercise: "Deadlift", value: "125kg", tag: "Nuevo Récord!", isRecord: true),
        .init(athlete: "Carlos Ruiz", exercise: "Fran WOD", value: "3:42", tag: "-15 seg", isRecord: false),
        .init(athlete: "Sofía Paz", exercise: "Snatch", value: "65kg", tag: "Nuevo Récord!", isRecord: true)
    ]
    static let mostImproved: [Improved] = [
        .init(name: "Marcos Vinicius", consistency: 98, delta: "+22%"),
        .init(name: "Lucía Fernández", consistency: 92, delta: "+18%"),
        .init(name: "Andrés Soler", consistency: 89, delta: "+15%")
    ]
}

// MARK: - Store (adherencia real: % de atletas activos que asistieron por día)

@MainActor @Observable
final class CommunityAdherenceStore {
    fileprivate var state: LoadState<[CommunityProgressData.Day]> = .loading
    private let repo = CoachRepository()
    private static let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    func load() async {
        state = .loading
        do {
            let days = try await repo.adherenceByDay(days: 7)
            let calendar = CoachRepository.calendar
            let mapped = days.map { entry in
                let weekday = calendar.component(.weekday, from: entry.date) // 1 = domingo
                let labelIndex = (weekday + 5) % 7 // domingo→6, lunes→0…
                return CommunityProgressData.Day(label: Self.dayLabels[labelIndex], value: entry.percent)
            }
            state = .loaded(mapped)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    CommunityProgressView(profile: .preview)
}
