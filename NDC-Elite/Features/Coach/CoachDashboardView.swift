import SwiftUI
import Charts

/// Tab 1 · Inicio del coach — diseño Stitch "Dashboard del Coach - Vista Estratégica".
/// Asistencia de hoy · validaciones pendientes (acción requerida) · rendimiento
/// semanal · próximo WOD · alertas de asistencia (contacto WhatsApp).
/// (ver FLOWS.md → CoachDashboardView)
///
/// Datos reales: attendance (hoy + últimos 30 días para ausencias),
/// wod_results + personal_records pendientes, wods (próximo publicado),
/// class_sessions (capacidad de hoy) y notifications (badge).
struct CoachDashboardView: View {
    let profile: Profile
    @State private var store = CoachDashboardStore()
    @State private var weeklyStore = CoachWeeklyPerformanceStore()
    @State private var showValidation = false
    @State private var showAlerts = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    greeting
                    LoadStateView(state: store.state, retry: { Task { await store.load() } }) { data in
                        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                            AttendanceTodayCard(attended: data.attendedToday, capacity: data.capacityToday)
                            PendingValidationsCard(count: data.pendingValidations, onReview: { showValidation = true })
                            WeeklyPerformanceCard(state: weeklyStore.state, retry: { Task { await weeklyStore.load() } })
                            if let wod = data.nextWod {
                                NextWodCard(wod: wod)
                            }
                            if !data.absenceAlerts.isEmpty {
                                attendanceAlerts(data.absenceAlerts)
                            }
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackLG) {
                            SkeletonCard(lines: 2, height: 120)
                            SkeletonCard(lines: 2, height: 100)
                            SkeletonCard(lines: 1, height: 160)
                        }
                    }
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
                    NDCBellButton(unreadCount: store.state.value?.unreadCount ?? 0) { showAlerts = true }
                }
            }
            .task {
                async let dashboard: Void = store.load()
                async let weekly: Void = weeklyStore.load()
                _ = await (dashboard, weekly)
            }
            .refreshable {
                async let dashboard: Void = store.load()
                async let weekly: Void = weeklyStore.load()
                _ = await (dashboard, weekly)
            }
            .onChange(of: showValidation) { _, isShowing in
                // Al volver de validar, refresca el contador de pendientes.
                if !isShowing { Task { await store.load() } }
            }
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

    private func attendanceAlerts(_ alerts: [CoachDashboardStore.AbsenceAlert]) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Alertas de Asistencia").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Text("\(alerts.count) Atletas")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
            }
            ForEach(alerts) { alert in
                AbsenceAlertRow(alert: alert)
            }
        }
    }
}

// MARK: - Asistencia de hoy

private struct AttendanceTodayCard: View {
    let attended: Int
    let capacity: Int

    private var percent: Int {
        capacity > 0 ? Int(Double(attended) / Double(capacity) * 100) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ASISTENCIA HOY").font(NDCFont.labelBold).foregroundStyle(.white.opacity(0.8)).tracking(1)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(attended)").font(NDCFont.statsXL).foregroundStyle(.white)
                        Text(capacity > 0 ? "/ \(capacity) cupos" : "check-ins").font(NDCFont.bodyMD).foregroundStyle(NDCColor.primaryFixed)
                    }
                }
                Spacer()
                if capacity > 0 {
                    Text("\(percent)%").font(NDCFont.displayLG).foregroundStyle(NDCColor.accent)
                }
            }
            if capacity > 0 {
                ProgressTrack(value: Double(attended) / Double(capacity),
                              tint: NDCColor.accent, track: .white.opacity(0.2))
            } else {
                Text("Programa las clases de hoy en Atletas → 📅 para ver la capacidad.")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Asistencia hoy: \(attended) de \(capacity) cupos")
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
                    Label(count > 0 ? "ACCIÓN REQUERIDA" : "AL DÍA",
                          systemImage: count > 0 ? "exclamationmark.circle.fill" : "checkmark.seal.fill")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(count > 0 ? NDCColor.error : .green)
                    Spacer()
                    Text("\(count) marcas")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(NDCColor.accent, in: .capsule)
                }
                Text("Validaciones Pendientes").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                HStack {
                    Text(count > 0 ? "Nuevas marcas esperando tu revisión crítica"
                                   : "No hay marcas esperando revisión")
                        .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                    Spacer()
                    Image(systemName: "arrow.right").foregroundStyle(NDCColor.primary)
                }
            }
            .padding(NDCSpacing.stackLG)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(count > 0 ? NDCColor.error.opacity(0.3) : NDCColor.outline.opacity(0.2), lineWidth: 1))
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

// MARK: - Próximo WOD (real)

private struct NextWodCard: View {
    let wod: Wod

    private var scheduleLabel: String {
        let cal = Calendar.current
        let prefix = cal.isDateInToday(wod.scheduledDate) ? "HOY"
            : cal.isDateInTomorrow(wod.scheduledDate) ? "MAÑANA"
            : {
                let f = DateFormatter()
                f.locale = Locale(identifier: "es_ES")
                f.dateFormat = "EEE d MMM"
                return f.string(from: wod.scheduledDate).uppercased()
            }()
        if let focus = wod.focus { return "\(prefix) • \(focus)" }
        return prefix
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text("Próximo WOD").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [NDCColor.primary, NDCColor.primaryDark], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                    HStack(spacing: NDCSpacing.stackSM) {
                        Text(scheduleLabel).font(NDCFont.labelBold).foregroundStyle(NDCColor.accent)
                        Text(wod.wodType.displayName).font(NDCFont.labelSM).foregroundStyle(.white)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(.white.opacity(0.15), in: .capsule)
                    }
                    Text(wod.title).font(NDCFont.headlineMD).foregroundStyle(.white)
                    if let notes = wod.notes ?? wod.description {
                        Text(notes).font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
                            .lineLimit(2)
                    }
                }
                .padding(NDCSpacing.stackLG)
            }
            .frame(height: 150)
            .clipShape(.rect(cornerRadius: NDCRadius.large))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Próximo WOD: \(wod.title), \(scheduleLabel)")
    }
}

// MARK: - Fila de alerta de ausencia (WhatsApp)

private struct AbsenceAlertRow: View {
    let alert: CoachDashboardStore.AbsenceAlert

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: alert.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Label(alert.daysLabel, systemImage: "clock.arrow.circlepath")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.error)
            }
            Spacer()
            if let phone = alert.phone {
                Button {
                    Haptics.impact()
                    WhatsAppHelper.sendAbsenceReminder(phone: phone, athleteName: alert.firstName, absentDays: alert.days)
                } label: {
                    Image(systemName: "message.fill")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(NDCColor.primary, in: .circle)
                }
                .accessibilityLabel("Contactar a \(alert.firstName) por WhatsApp")
            }
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

// MARK: - Store (dashboard real del coach)

@MainActor @Observable
final class CoachDashboardStore {
    struct AbsenceAlert: Identifiable {
        let id: UUID
        let name: String
        let avatarURL: String?
        let days: Int
        let phone: String?

        var firstName: String { name.components(separatedBy: " ").first ?? name }
        var daysLabel: String { days >= 30 ? "Ausente: 30+ días" : "Ausente: \(days) días" }
    }

    struct Data {
        let attendedToday: Int
        let capacityToday: Int
        let pendingValidations: Int
        let nextWod: Wod?
        let absenceAlerts: [AbsenceAlert]
        let unreadCount: Int
    }

    private(set) var state: LoadState<Data> = .loading
    private let repo = CoachRepository()
    private let athleteRepo = AthleteRepository()

    /// Ausencia mínima para alertar (días sin venir).
    private static let absenceThreshold = 4

    func load() async {
        state = .loading
        do {
            async let attendedTask = repo.presentCountToday()
            async let sessionsTask = repo.sessions(on: Date())
            async let pendingResultsTask = repo.pendingWodResults()
            async let pendingPrsTask = repo.pendingPersonalRecords()
            async let nextWodTask = athleteRepo.nextWod()
            async let athletesTask = repo.athletes()
            async let presenceTask = repo.recentPresence(days: 30)

            let capacity = (try await sessionsTask).reduce(0) { $0 + $1.capacity }
            let pending = (try await pendingResultsTask).count + (try await pendingPrsTask).count
            let alerts = Self.absenceAlerts(
                athletes: try await athletesTask,
                presence: try await presenceTask
            )
            let unread = (try? await athleteRepo.unreadNotifications(
                userId: SupabaseManager.client.auth.currentSession?.user.id ?? UUID()
            )) ?? 0

            state = .loaded(Data(
                attendedToday: try await attendedTask,
                capacityToday: capacity,
                pendingValidations: pending,
                nextWod: try await nextWodTask,
                absenceAlerts: alerts,
                unreadCount: unread
            ))
        } catch {
            state = .failed("No pudimos cargar el resumen. Revisa tu conexión e inténtalo de nuevo.")
        }
    }

    /// Atletas con más días sin venir (los 3 peores sobre el umbral).
    private static func absenceAlerts(athletes: [Profile], presence: [Attendance]) -> [AbsenceAlert] {
        var lastSeen: [UUID: Date] = [:]
        for row in presence {
            guard let date = row.checkedInAt else { continue }
            lastSeen[row.athleteId] = max(lastSeen[row.athleteId] ?? .distantPast, date)
        }
        let today = Calendar.current.startOfDay(for: Date())
        let alerts = athletes.compactMap { athlete -> AbsenceAlert? in
            let days: Int
            if let seen = lastSeen[athlete.id] {
                days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: seen), to: today).day ?? 0
            } else {
                days = 30 // sin registro en la ventana consultada
            }
            guard days >= absenceThreshold else { return nil }
            return AbsenceAlert(id: athlete.id, name: athlete.fullName,
                                avatarURL: athlete.avatarURL, days: days, phone: athlete.phone)
        }
        return Array(alerts.sorted { $0.days > $1.days }.prefix(3))
    }
}

// MARK: - Store (asistencia semanal real, agregada de todo el box)

@MainActor @Observable
final class CoachWeeklyPerformanceStore {
    struct Weekly {
        struct Bar: Identifiable { let id = UUID(); let day: String; let value: Double }
        let bars: [Bar]
        let deltaLabel: String
    }

    private(set) var state: LoadState<Weekly> = .loading
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

            let bars = (0..<7).map { offset -> Weekly.Bar in
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
