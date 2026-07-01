import SwiftUI
import Charts

/// Detalle de un PR / logro — diseño Stitch "Detalle de Logro: Sentadilla Trasera".
/// Vista **empujada** dentro del tab Progreso (back · "Detalle de Récord" · compartir;
/// el navbar inferior permanece). Hero del récord · bento (fecha/nivel/% previo) ·
/// evolución histórica (gráfico) · notas · Compartir Logro · banner.
/// (ver FLOWS.md → PrDetailView)
///
/// Muestra la marca personal más reciente del atleta y su evolución real
/// (`personal_records` del ejercicio, agrupadas por `exercise_id`).
struct PrDetailView: View {
    let profile: Profile
    @State private var store = PrDetailStore()
    @State private var shareImage: Image?

    var body: some View {
        ScrollView {
            LoadStateView(
                state: store.state,
                retry: { Task { await store.load(athleteId: profile.id) } }
            ) { data in
                Group {
                    if let data {
                        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                            heroCard(data)
                            statsBento(data)
                            evolutionChart(data)
                            if let notes = data.notes {
                                notesCard(notes)
                            }
                            shareButton(data)
                            contextBanner
                        }
                        .onAppear { renderShareImage(data) }
                    } else {
                        ContentUnavailableView(
                            "Aún sin marcas",
                            systemImage: "trophy",
                            description: Text("Registra tu primer PR para ver su evolución aquí.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    }
                }
            } skeleton: {
                VStack(spacing: NDCSpacing.stackLG) {
                    SkeletonCard(lines: 3, height: 150)
                    SkeletonCard(lines: 2, height: 90)
                    SkeletonCard(lines: 1, height: 180)
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Detalle de Récord")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let data = store.state.value ?? nil {
                    achievementShareLink(data: data) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(NDCColor.primary)
                    }
                }
            }
        }
        .task { await store.load(athleteId: profile.id) }
        .refreshable { await store.load(athleteId: profile.id) }
    }

    /// ShareLink que comparte la imagen deportiva del logro (con texto de respaldo
    /// mientras se renderiza). Reutilizado por la barra y por "Compartir Logro".
    @ViewBuilder
    private func achievementShareLink<Label: View>(data: PrDetailData, @ViewBuilder label: () -> Label) -> some View {
        Group {
            if let shareImage {
                ShareLink(
                    item: shareImage,
                    subject: Text("Nuevo PR en \(data.exercise)"),
                    message: Text(data.shareText),
                    preview: SharePreview("\(data.exercise) — \(data.value)", image: shareImage),
                    label: label
                )
            } else {
                ShareLink(item: data.shareText, label: label)
            }
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.impact() })
    }

    @MainActor private func renderShareImage(_ data: PrDetailData) {
        guard shareImage == nil else { return }
        let renderer = ImageRenderer(
            content: ShareableAchievementCard(data: data, athleteName: profile.fullName)
        )
        renderer.scale = 3
        if let ui = renderer.uiImage {
            shareImage = Image(uiImage: ui)
        }
    }

    // MARK: - Hero del récord

    private func heroCard(_ data: PrDetailData) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(data.badge)
                .font(NDCFont.labelBold)
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(NDCColor.secondary, in: .capsule)
            Text(data.exercise)
                .font(NDCFont.displayLG)
                .foregroundStyle(.white)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(data.value)
                    .font(NDCFont.statsXL)
                    .foregroundStyle(NDCColor.accent)
                Text(data.delta)
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.accent.opacity(0.9))
            }
            Text("PROGRESO VS MARCA ANTERIOR")
                .font(NDCFont.labelSM)
                .foregroundStyle(.white.opacity(0.8))
                .tracking(1)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(data.badge). \(data.exercise), \(data.value), \(data.delta) sobre la marca anterior")
    }

    // MARK: - Bento de stats

    private func statsBento(_ data: PrDetailData) -> some View {
        VStack(spacing: NDCSpacing.gutter) {
            HStack(spacing: NDCSpacing.gutter) {
                miniStat(icon: "calendar", label: "Fecha", value: data.dateLabel)
                miniStat(icon: "star.fill", label: "Nivel", value: data.level)
            }
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Relación % Marca Anterior")
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.outline)
                    Text(data.ratioLabel)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.primary)
                }
                Spacer()
                Text(data.ringLabel)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(NDCColor.accent, lineWidth: 4))
            }
            .padding(NDCSpacing.gutter)
            .frame(maxWidth: .infinity)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private func miniStat(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Image(systemName: icon).foregroundStyle(NDCColor.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                Text(value)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
        }
        .padding(NDCSpacing.gutter)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Evolución histórica (gráfico)

    private func evolutionChart(_ data: PrDetailData) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Evolución Histórica")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
                Spacer()
                Text("Últimos 6 meses")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
            }
            Chart(data.history) { point in
                AreaMark(
                    x: .value("Mes", point.month),
                    y: .value("kg", point.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [NDCColor.primary.opacity(0.25), NDCColor.primary.opacity(0.02)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Mes", point.month),
                    y: .value("kg", point.value)
                )
                .foregroundStyle(NDCColor.primary)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)

                if point.id == data.history.last?.id {
                    PointMark(
                        x: .value("Mes", point.month),
                        y: .value("kg", point.value)
                    )
                    .foregroundStyle(NDCColor.accent)
                    .symbolSize(120)
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.outline)
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Evolución histórica del PR en los últimos 6 meses")
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.outline.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: NDCColor.primaryDark.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Notas del atleta

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Label("NOTAS DEL ATLETA", systemImage: "square.and.pencil")
                .font(NDCFont.labelBold)
                .foregroundStyle(NDCColor.primary)
            Text("\"\(notes)\"")
                .font(NDCFont.bodyLG)
                .italic()
                .foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(NDCColor.secondary)
                .frame(width: 4)
                .clipShape(.rect(cornerRadii: .init(topLeading: NDCRadius.large, bottomLeading: NDCRadius.large)))
        }
    }

    // MARK: - Compartir logro

    private func shareButton(_ data: PrDetailData) -> some View {
        achievementShareLink(data: data) {
            Label("Compartir Logro", systemImage: "square.and.arrow.up")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.2), radius: 8, y: 4)
        }
    }

    // MARK: - Banner de contexto

    private var contextBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [NDCColor.primary, NDCColor.primaryDark],
                startPoint: .topTrailing, endPoint: .bottomLeading
            )
            LinearGradient(
                colors: [NDCColor.primaryDark.opacity(0.6), .clear],
                startPoint: .bottom, endPoint: .top
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("NDC HQ Elite Performance")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(.white)
                Text("High Standards Only")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.accent)
            }
            .padding(NDCSpacing.stackLG)
        }
        .frame(height: 160)
        .clipShape(.rect(cornerRadius: NDCRadius.large))
        .accessibilityHidden(true)
    }
}

// MARK: - Tarjeta compartible (imagen para redes sociales)

/// Diseño deportivo y elegante que se renderiza a imagen (`ImageRenderer`) para
/// que el atleta comparta su PR en redes. Formato vertical tipo post (4:5).
private struct ShareableAchievementCard: View {
    let data: PrDetailData
    let athleteName: String

    var body: some View {
        ZStack {
            // Fondo deportivo
            LinearGradient(
                colors: [NDCColor.primary, NDCColor.primaryDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            // Marca de agua
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 260, weight: .black))
                .foregroundStyle(.white.opacity(0.05))
                .rotationEffect(.degrees(-18))
                .offset(x: 70, y: 90)

            VStack(alignment: .leading, spacing: 0) {
                // Marca
                HStack {
                    Text("NDC HQ")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("PERFORMANCE")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(NDCColor.accent)
                }

                Spacer()

                Text("NUEVO RÉCORD")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(NDCColor.accent, in: .capsule)

                Text(data.exercise)
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 12)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(data.value)
                        .font(.system(size: 72, weight: .black))
                        .foregroundStyle(NDCColor.accent)
                    Text(data.delta)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(NDCColor.accent.opacity(0.9))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                Text("vs. su marca anterior")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))

                Spacer()

                // Pie: atleta + fecha
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(athleteName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                        Text(data.dateLabel)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                Rectangle().fill(.white.opacity(0.15)).frame(height: 1).padding(.vertical, 14)
                Text("HIGH STANDARDS ONLY · #NDCHQ")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(NDCColor.accent)
            }
            .padding(28)
            .frame(width: 360, height: 450, alignment: .topLeading)
        }
        .frame(width: 360, height: 450)
        .clipped()
    }
}

// MARK: - Datos del récord (poblados desde `personal_records` reales)

struct PrDetailData {
    struct HistoryPoint: Identifiable {
        let id = UUID()
        let month: String
        let value: Double
    }

    let badge: String
    let exercise: String
    let value: String
    let delta: String
    let dateLabel: String
    let level: String
    let ratioLabel: String
    let ringLabel: String
    let notes: String?
    let history: [HistoryPoint]
    var shareText: String { "¡Nuevo PR en \(exercise): \(value) (\(delta))! 💪 #NDCHQ" }
}

// MARK: - Store (última marca real del atleta + su evolución)

@MainActor @Observable
final class PrDetailStore {
    /// `.loaded(nil)` = el atleta aún no tiene ninguna marca registrada.
    private(set) var state: LoadState<PrDetailData?> = .loading
    private let repo = AthleteRepository()

    func load(athleteId: UUID) async {
        state = .loading
        do {
            let records = try await repo.personalRecords(athleteId: athleteId)
            guard let latest = records.max(by: { $0.recordDate < $1.recordDate }) else {
                state = .loaded(nil)
                return
            }
            let exercises = try await repo.exercises(ids: [latest.exerciseId])
            let exercise = exercises.first
            let history = records
                .filter { $0.exerciseId == latest.exerciseId }
                .sorted { $0.recordDate < $1.recordDate }

            state = .loaded(Self.buildData(latest: latest, exercise: exercise, history: history))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func buildData(latest: PersonalRecord, exercise: Exercise?, history: [PersonalRecord]) -> PrDetailData {
        let value = Self.formatValue(latest.value, scoreType: latest.scoreType)
        let delta: String
        let ratioLabel: String
        let ringLabel: String
        if let previous = latest.previousValue, previous > 0 {
            let diff = latest.value - previous
            let sign = diff >= 0 ? "+" : ""
            delta = "\(sign)\(Self.formatValue(diff, scoreType: latest.scoreType))"
            let ratio = (latest.value / previous) * 100
            ratioLabel = "\(Int(ratio.rounded()))% del PR previo"
            ringLabel = "\(Int(ratio.rounded()))%"
        } else {
            delta = "Nuevo"
            ratioLabel = "Primera marca registrada"
            ringLabel = "—"
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "es_ES")
        monthFormatter.dateFormat = "MMM"
        let dateLabelFormatter = DateFormatter()
        dateLabelFormatter.locale = Locale(identifier: "es_ES")
        dateLabelFormatter.dateFormat = "d MMM"

        return PrDetailData(
            badge: latest.previousValue == nil ? "PRIMER RÉCORD" : "NUEVO RÉCORD",
            exercise: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
            value: value,
            delta: delta,
            dateLabel: Self.isToday(latest.recordDate) ? "Hoy, \(dateLabelFormatter.string(from: latest.recordDate))" : dateLabelFormatter.string(from: latest.recordDate),
            level: exercise?.difficulty.displayName ?? "—",
            ratioLabel: ratioLabel,
            ringLabel: ringLabel,
            notes: latest.athleteNotes,
            history: history.suffix(6).map {
                .init(month: monthFormatter.string(from: $0.recordDate).capitalized, value: $0.value)
            }
        )
    }

    private static func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private static func formatValue(_ value: Double, scoreType: ScoreType) -> String {
        switch scoreType {
        case .peso:
            value == value.rounded() ? "\(Int(value))kg" : String(format: "%.1fkg", value)
        case .tiempo:
            Self.formatSeconds(value)
        case .reps:
            "\(Int(value)) reps"
        case .rondas:
            "\(Int(value)) rondas"
        case .distancia:
            String(format: "%.1fkm", value)
        case .calorias:
            "\(Int(value)) cal"
        }
    }

    private static func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

#Preview {
    NavigationStack { PrDetailView(profile: .preview) }
}
