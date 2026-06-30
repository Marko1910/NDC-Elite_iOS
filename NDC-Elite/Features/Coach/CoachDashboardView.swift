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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    greeting
                    AttendanceTodayCard(data: data)
                    PendingValidationsCard(count: data.pendingValidations, onReview: {})
                    WeeklyPerformanceCard(data: data)
                    NextWodCard(wod: data.nextWod)
                    attendanceAlerts
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { brandLabel }
                ToolbarItem(placement: .topBarTrailing) {
                    NDCBellButton(unreadCount: data.unreadCount) { /* TODO: → CoachAlertsView */ }
                }
            }
        }
        .tint(NDCColor.primary)
    }

    private var brandLabel: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            NDCAvatarView(urlString: profile.avatarURL, size: 32)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text("NDC HQ").font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                Text(data.liveClass).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("¡Hola, Coach!")
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

// MARK: - Rendimiento semanal (gráfico real)

private struct WeeklyPerformanceCard: View {
    let data: CoachDashboardData

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Rendimiento Semanal").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Label(data.weeklyDelta, systemImage: "arrow.up.right")
                    .font(NDCFont.labelBold).foregroundStyle(.green)
            }
            Chart(data.weeklyBars) { bar in
                BarMark(x: .value("Día", bar.day), y: .value("Valor", bar.value))
                    .foregroundStyle(NDCColor.primary)
                    .cornerRadius(4)
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in AxisValueLabel().font(NDCFont.labelSM) }
            }
            .frame(height: 120)
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

    let liveClass: String
    let attendedToday: Int
    let capacityToday: Int
    let attendancePercent: Int
    let pendingValidations: Int
    let weeklyDelta: String
    let weeklyBars: [Bar]
    let nextWod: NextWod
    let absenceAlerts: [AbsenceAlert]
    let unreadCount: Int

    static let sample = CoachDashboardData(
        liveClass: "Box en vivo: Clase 07:00 AM",
        attendedToday: 42, capacityToday: 50, attendancePercent: 84,
        pendingValidations: 8,
        weeklyDelta: "+12% vs anterior",
        weeklyBars: [
            .init(day: "L", value: 38), .init(day: "M", value: 42), .init(day: "X", value: 40),
            .init(day: "J", value: 45), .init(day: "V", value: 48), .init(day: "S", value: 30),
            .init(day: "D", value: 12)
        ],
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

#Preview {
    CoachDashboardView(profile: .preview)
}
