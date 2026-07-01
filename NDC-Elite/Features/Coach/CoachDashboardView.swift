import SwiftUI
import Charts

/// Tab 1 · Inicio del coach — diseño Stitch "Dashboard del Coach - Vista Estratégica".
/// Asistencia de hoy · validaciones pendientes (acción requerida) · rendimiento
/// semanal · próximo WOD · alertas de asistencia (contacto WhatsApp).
/// (ver FLOWS.md → CoachDashboardView)
///
/// TODO(datos): hoy usa `CoachDashboardData.sample`. Conectar a Supabase:
/// attendance (hoy), wod_results+personal_records (pendientes), wods (próximo),
/// attendance agregada (ausencias prolongadas).
struct CoachDashboardView: View {
    let profile: Profile
    private let data = CoachDashboardData.sample
    @State private var weeklyStore = CoachWeeklyPerformanceStore()
    @State private var showValidation = false
    @State private var showAlerts = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    greeting
                    AttendanceTodayCard(data: data)
                    PendingValidationsCard(count: data.pendingValidations, onReview: { showValidation = true })
                    WeeklyPerformanceCard(state: weeklyStore.state, retry: { Task { await weeklyStore.load() } })
                    NextWodCard(wod: data.nextWod)
                    attendanceAlerts
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $showValidation) { ValidationView() }
            .navigationDestination(isPresented: $showAlerts) { CoachAlertsView(profile: profile) }
            .navigationTitle("NDC HQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NDCBellButton(unreadCount: data.unreadCount) { showAlerts = true }
                }
            }
            .task { await weeklyStore.load() }
            .refreshable { await weeklyStore.load() }
        }
        .tint(NDCColor.primary)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("¡Hola, \(profile.firstName)!")
                .font(NDCFont.displayLG).foregroundStyle(NDCColor.primaryDark)
            Text("Resumen estratégico de hoy")
                .font(NDCFont.bodyLG).foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .accessibilityElement(children: .combine)
    }

    private var attendanceAlerts: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Alertas de Asistencia").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Text("\(data.absenceAlerts.count) Críticas")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
            }
            ForEach(data.absenceAlerts) { alert in
                AbsenceAlertRow(alert: alert)
            }
        }
    }
}

// MARK: - Asistencia de hoy

private struct AttendanceTodayCard: View {
    let data: CoachDashboardData

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ASISTENCIA HOY").font(NDCFont.labelBold).foregroundStyle(.white.opacity(0.8)).tracking(1)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(data.attendedToday)").font(NDCFont.statsXL).foregroundStyle(.white)
                        Text("/ \(data.capacityToday) cupos llenos").font(NDCFont.bodyMD).foregroundStyle(NDCColor.primaryFixed)
                    }
                }
                Spacer()
                Text("\(data.attendancePercent)%").font(NDCFont.displayLG).foregroundStyle(NDCColor.accent)
            }
            ProgressTrack(value: Double(data.attendedToday) / Double(data.capacityToday),
                          tint: NDCColor.accent, track: .white.opacity(0.2))
            Text("Quedan \(data.capacityToday - data.attendedToday) lugares disponibles para la mañana")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Asistencia hoy: \(data.attendancePercent) por ciento, \(data.attendedToday) de \(data.capacityToday) cupos")
    }
}

// MARK: - Validaciones pendientes

private struct PendingValidationsCard: View {
    let count: Int
    let onReview: () -> Void

    var body: some View {
        Button {
            Haptics.impact()
            onReview()
        } label: {
            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                HStack {
                    Label("ACCIÓN REQUERIDA", systemImage: "exclamationmark.circle.fill")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    Spacer()
                    Text("\(count) PRs")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(NDCColor.accent, in: .capsule)
                }
                Text("Validaciones Pendientes").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                HStack {
                    Text("Nuevas marcas esperando tu revisión crítica")
                        .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(NDCColor.primary)
                }
            }
            .padding(NDCSpacing.stackLG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.error.opacity(0.3), lineWidth: 1))
        }
        .accessibilityHint("Revisar \(count) validaciones pendientes")
    }
}

// MARK: - Rendimiento semanal (gráfico real: asistencia "presente" por día)

private struct WeeklyPerformanceCard: View {
    let state: LoadState<CoachWeeklyPerformanceStore.Weekly>
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            LoadStateView(state: state, retry: retry) { weekly in
                VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                    HStack {
                        Text("Rendimiento Semanal").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                        Spacer()
                        Label(weekly.deltaLabel, systemImage: "arrow.up.right")
                            .font(NDCFont.labelBold).foregroundStyle(.green)
                    }
                    Chart(weekly.bars) { bar in
                        BarMark(x: .value("Día", bar.day), y: .value("Asistencias", bar.value))
                            .foregroundStyle(NDCColor.primary)
                            .cornerRadius(4)
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks { _ in AxisValueLabel().font(NDCFont.labelSM) }
                    }
                    .frame(height: 120)
                }
            } skeleton: {
                SkeletonCard(lines: 1, height: 160)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Próximo WOD

private struct NextWodCard: View {
    let wod: CoachDashboardData.NextWod

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                Text("Próximo WOD").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Label("Ver detalles", systemImage: "arrow.up.forward.square")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primary)
            }
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [NDCColor.primary, NDCColor.primaryDark], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                    HStack(spacing: NDCSpacing.stackSM) {
                        Text(wod.schedule).font(NDCFont.labelBold).foregroundStyle(NDCColor.accent)
                        ForEach(wod.levels, id: \.self) { lv in
                            Text(lv).font(NDCFont.labelSM).foregroundStyle(.white)
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(.white.opacity(0.15), in: .capsule)
                        }
                    }
                    Text(wod.title).font(NDCFont.headlineMD).foregroundStyle(.white)
                    Text(wod.summary).font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }
                .padding(NDCSpacing.stackLG)
            }
            .frame(height: 150)
            .clipShape(.rect(cornerRadius: NDCRadius.large))
        }
    }
}

// MARK: - Fila de alerta de ausencia (WhatsApp)

private struct AbsenceAlertRow: View {
    let alert: CoachDashboardData.AbsenceAlert

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: nil, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Label("Ausente: \(alert.days) días", systemImage: "clock.arrow.circlepath")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.error)
                if alert.atRisk {
                    Text("Retención en riesgo").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
            }
            Spacer()
            Button {
                Haptics.impact()
                WhatsAppHelper.sendAbsenceReminder(phone: alert.phone, athleteName: alert.firstName, absentDays: alert.days)
            } label: {
                Image(systemName: "message.fill")
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(NDCColor.primary, in: .circle)
            }
            .accessibilityLabel("Contactar a \(alert.firstName) por WhatsApp")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }
}

// MARK: - Barra de progreso

private struct ProgressTrack: View {
    let value: Double
    var tint: Color
    var track: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint).frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct CoachDashboardData {
    struct Bar: Identifiable { let id = UUID(); let day: String; let value: Double }
    struct NextWod { let schedule, title, summary: String; let levels: [String] }
    struct AbsenceAlert: Identifiable {
        let id = UUID(); let name: String; let days: Int; let atRisk: Bool; let phone: String
        var firstName: String { name.components(separatedBy: " ").first ?? name }
    }

    let attendedToday: Int
    let capacityToday: Int
    let attendancePercent: Int
    let pendingValidations: Int
    let nextWod: NextWod
    let absenceAlerts: [AbsenceAlert]
    let unreadCount: Int

    static let sample = CoachDashboardData(
        attendedToday: 42, capacityToday: 50, attendancePercent: 84,
        pendingValidations: 8,
        nextWod: NextWod(schedule: "MAÑANA • 06:00 AM",
                         title: "MURPH PREP",
                         summary: "1 Mile Run, 100 Pull-ups, 200 Push-ups, 300 Air Squats, 1 Mile Run.",
                         levels: ["RX", "Scaled"]),
        absenceAlerts: [
            .init(name: "Mateo Rodríguez", days: 6, atRisk: true, phone: "+51987654321"),
            .init(name: "Carla Méndez", days: 5, atRisk: false, phone: "+51987654322"),
            .init(name: "Javier Soler", days: 4, atRisk: false, phone: "+51987654323")
        ],
        unreadCount: 3
    )
}

// MARK: - Store (asistencia semanal real, agregada de todo el box)

@MainActor @Observable
final class CoachWeeklyPerformanceStore {
    fileprivate struct Weekly {
        let bars: [CoachDashboardData.Bar]
        let deltaLabel: String
    }

    fileprivate var state: LoadState<Weekly> = .loading
    private let repo = CoachRepository()
    private static let dayLabels = ["L", "M", "X", "J", "V", "S", "D"]

    func load() async {
        state = .loading
        do {
            let calendar = CoachRepository.calendar
            let now = Date()
            let thisWeekStart = CoachRepository.startOfWeek(containing: now)
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!

            async let thisWeekTask = repo.weeklyAttendanceCounts(containing: now)
            async let lastWeekTask = repo.weeklyAttendanceCounts(containing: lastWeekStart)
            let (thisWeek, lastWeek) = try await (thisWeekTask, lastWeekTask)

            let bars = (0..<7).map { offset -> CoachDashboardData.Bar in
                let day = calendar.date(byAdding: .day, value: offset, to: thisWeekStart)!
                return .init(day: Self.dayLabels[offset], value: Double(thisWeek[day] ?? 0))
            }
            let thisTotal = thisWeek.values.reduce(0, +)
            let lastTotal = lastWeek.values.reduce(0, +)
            let deltaLabel: String
            if lastTotal == 0 {
                deltaLabel = thisTotal == 0 ? "Sin datos aún" : "+100% vs anterior"
            } else {
                let pct = (Double(thisTotal - lastTotal) / Double(lastTotal)) * 100
                deltaLabel = "\(pct >= 0 ? "+" : "")\(Int(pct.rounded()))% vs anterior"
            }
            state = .loaded(Weekly(bars: bars, deltaLabel: deltaLabel))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

#Preview {
    CoachDashboardView(profile: .preview)
}
