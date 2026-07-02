import SwiftUI

/// Tab 1 · Inicio del atleta — diseño Stitch "NDC HQ - Dashboard".
/// Estructura: saludo · logro desbloqueado · WOD del día · stats (asistencia/récords)
/// · próximo objetivo · tip del coach. (ver FLOWS.md → AthleteDashboardView)
///
/// Datos reales de Supabase: wods (próximo publicado + su metcon), attendance
/// (mes en curso), personal_records (últimos 30 días), athlete_goals,
/// coach_tips y notifications (badge). Secciones sin datos se ocultan solas.
struct AthleteDashboardView: View {
    let profile: Profile
    /// Lleva al tab WOD (lo inyecta AthleteTabView).
    var openWod: () -> Void = {}
    @State private var store = AthleteDashboardStore()
    @State private var showNotifications = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    greeting
                    LoadStateView(state: store.state, retry: { Task { await store.load(profile: profile) } }) { data in
                        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                            if let achievement = data.unlockedAchievement {
                                PRAlertCard(text: achievement)
                            }
                            if let wod = data.wod {
                                WODCard(wod: wod, onOpen: openWod)
                            }
                            StatsRow(
                                attended: data.attendedSessions,
                                goal: profile.monthlyAttendanceGoal,
                                prCount: data.prCount
                            )
                            if let goal = data.nextGoal {
                                NextGoalCard(goal: goal)
                            }
                            if let tip = data.coachTip {
                                CoachTipCard(tip: tip, onPlay: { /* TODO: → ExerciseDetailView */ })
                            }
                        }
                    } skeleton: {
                        DashboardSkeleton()
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, 96) // espacio para el FAB
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NDCBellButton(unreadCount: store.state.value?.unreadCount ?? 0) {
                        showNotifications = true
                    }
                }
            }
            .sheet(isPresented: $showNotifications, onDismiss: {
                // Refresca el badge: la bandeja marcó todo como leído.
                Task { await store.load(profile: profile) }
            }) {
                AthleteNotificationsView(profile: profile)
            }
            .task { await store.load(profile: profile) }
            .refreshable { await store.load(profile: profile) }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Saludo

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("¡Hola, \(profile.firstName)!")
                .font(NDCFont.displayLG)
                .foregroundStyle(NDCColor.primaryDark)
            Text("¿Listo para tu sesión NDC?")
                .font(NDCFont.bodyLG)
                .foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .accessibilityElement(children: .combine)
    }

}

// MARK: - Logro desbloqueado (alerta amarilla)

private struct PRAlertCard: View {
    let text: String

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: "star.fill")
                .foregroundStyle(NDCColor.onAccent)
                .frame(width: 36, height: 36)
                .background(NDCColor.accent, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("LOGRO DESBLOQUEADO")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .tracking(0.5)
                Text(text)
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primaryDark)
            }
            Spacer(minLength: 0)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.accent.opacity(0.20), in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.accent, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Logro desbloqueado: \(text)")
    }
}

// MARK: - WOD del día (tarjeta Celeste Oscuro)

private struct WODCard: View {
    let wod: DashboardData.WOD
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text("WOD del día")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
                .padding(.leading, 2)

            VStack(spacing: NDCSpacing.stackMD) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                        Text("WOD: \"\(wod.name)\"")
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.onAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(NDCColor.accent, in: .capsule)
                        Text(wod.timeCap)
                            .font(NDCFont.displayLG)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "timer")
                        .font(.system(size: 32))
                        .foregroundStyle(NDCColor.accent)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 6) {
                    Text(wod.scheme)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.accent)
                    ForEach(wod.movements, id: \.self) { line in
                        Text(line)
                            .font(NDCFont.bodyMD)
                            .foregroundStyle(NDCColor.primaryFixed)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, NDCSpacing.stackMD)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.10))
                        .frame(height: 1)
                }

                Button {
                    Haptics.impact()
                    onOpen()
                } label: {
                    Text("Ver WOD")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
                }
                .accessibilityHint("Abre el detalle del entrenamiento del día")
            }
            .padding(NDCSpacing.stackLG)
            .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
            .shadow(color: NDCColor.primaryDark.opacity(0.08), radius: 12, y: 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("WOD del día: \(wod.name), tiempo objetivo \(wod.timeCap)")
    }
}

// MARK: - Stats bento (asistencia + récords)

private struct StatsRow: View {
    let attended: Int
    let goal: Int
    let prCount: Int

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            StatCard(
                icon: "calendar", label: "Asistencia", caption: "Sesiones este mes",
                a11y: "Asistencia: \(attended) de \(goal) sesiones este mes"
            ) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(attended)")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(NDCColor.primaryDark)
                    Text("/\(goal)")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.outline)
                }
            }
            StatCard(
                icon: "chart.line.uptrend.xyaxis", label: "Récords", caption: "Últimos 30 días",
                a11y: "Récords: \(prCount) en los últimos 30 días, en aumento"
            ) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(prCount)")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(NDCColor.primaryDark)
                    Image(systemName: "arrow.up")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.onAccent)
                }
            }
        }
    }
}

private struct StatCard<Value: View>: View {
    let icon: String
    let label: String
    let caption: String
    /// Texto leído por VoiceOver (los números sueltos no se entienden).
    let a11y: String
    @ViewBuilder var value: Value

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(NDCColor.primary)
                Spacer()
                Text(label)
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
            value
            Text(caption)
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a11y)
    }
}

// MARK: - Próximo objetivo (barra de progreso)

private struct NextGoalCard: View {
    let goal: DashboardData.Goal

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Próximo Objetivo")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.primaryDark)
                    Text(goal.title)
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.outline)
                }
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primaryDark)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(NDCColor.surface)
                    Capsule()
                        .fill(NDCColor.accent)
                        .frame(width: geo.size.width * goal.progress)
                        .shadow(color: NDCColor.accent, radius: 4)
                }
            }
            .frame(height: 12)

            HStack {
                Text("Actual: \(goal.currentLabel)")
                Spacer()
                Text("Meta: \(goal.targetLabel)")
            }
            .font(NDCFont.labelSM)
            .foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.08), radius: 12, y: 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Próximo objetivo: \(goal.title)")
        .accessibilityValue("\(Int(goal.progress * 100)) por ciento. Actual \(goal.currentLabel), meta \(goal.targetLabel)")
    }
}

// MARK: - Tip del coach (banner con imagen)

private struct CoachTipCard: View {
    let tip: DashboardData.CoachTip
    let onPlay: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            // Placeholder visual del fondo fotográfico (TODO: thumbnail de coach_tips)
            LinearGradient(
                colors: [NDCColor.primary, NDCColor.primaryDark],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [NDCColor.primaryDark.opacity(0.85), .clear],
                startPoint: .bottom, endPoint: .top
            )
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TIPS DEL COACH")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.accent)
                        .tracking(0.5)
                    Text(tip.title)
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(.white)
                }
                Spacer()
                Button {
                    Haptics.impact(.light)
                    onPlay()
                } label: {
                    Image(systemName: "play.fill")
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.20), in: .circle)
                }
                .accessibilityLabel("Reproducir tip")
            }
            .padding(NDCSpacing.stackLG)
        }
        .frame(height: 192)
        .clipShape(.rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Tip del coach: \(tip.title)")
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

struct DashboardData {
    struct WOD {
        let name: String
        let timeCap: String
        let scheme: String
        let movements: [String]
    }
    struct Goal {
        let title: String
        let progress: Double
        let currentLabel: String
        let targetLabel: String
    }
    struct CoachTip {
        let title: String
    }

    let unlockedAchievement: String?
    let wod: WOD?
    let attendedSessions: Int
    let prCount: Int
    let nextGoal: Goal?
    let coachTip: CoachTip?
    let unreadCount: Int

    static let sample = DashboardData(
        unlockedAchievement: "¡Nuevo récord en Clean!",
        wod: WOD(
            name: "EL TITÁN",
            timeCap: "12:45 min",
            scheme: "5 ROUNDS FOR TIME",
            movements: [
                "21 Power Clean (60/40kg)",
                "15 Toes to Bar",
                "9 Box Jumps (24/20\")"
            ]
        ),
        attendedSessions: 18,
        prCount: 5,
        nextGoal: Goal(
            title: "Muscle Ups (Consecutivos)",
            progress: 0.85,
            currentLabel: "8 reps",
            targetLabel: "10 reps"
        ),
        coachTip: CoachTip(title: "Mejora tu eficiencia en el Clean"),
        unreadCount: 2
    )
}

// MARK: - Store (carga de datos desde Supabase)

@MainActor @Observable
final class AthleteDashboardStore {
    private(set) var state: LoadState<DashboardData> = .loading
    private let repo = AthleteRepository()

    func load(profile: Profile) async {
        state = .loading
        do {
            async let attendanceTask = repo.monthlyAttendance(athleteId: profile.id)
            async let prTask = repo.recentPrCount(athleteId: profile.id)
            async let goalTask = repo.primaryGoal(athleteId: profile.id)
            async let tipTask = repo.latestTip()
            async let unreadTask = repo.unreadNotifications(userId: profile.id)

            // WOD del día + su bloque metcon (para el resumen).
            var wodVM: DashboardData.WOD?
            if let wod = try await repo.nextWod() {
                let blocks = try await repo.blocks(for: wod.id)
                let metcon = blocks.first(where: { $0.blockType == .metcon }) ?? blocks.last
                var movements: [String] = []
                var scheme = wod.focus ?? wod.wodType.displayName
                if let metcon {
                    movements = (try await repo.blockExercises(for: metcon.id)).map(\.prescription)
                    if let rounds = metcon.rounds { scheme = "\(rounds) ROUNDS FOR TIME" }
                }
                let timeCap = wod.timeCapMinutes.map { "\($0):00 min" } ?? wod.wodType.displayName
                wodVM = DashboardData.WOD(name: wod.title, timeCap: timeCap, scheme: scheme, movements: movements)
            }

            var goalVM: DashboardData.Goal?
            if let goal = try await goalTask {
                let unit = goal.unit ?? ""
                goalVM = DashboardData.Goal(
                    title: goal.title,
                    progress: goal.progress,
                    currentLabel: "\(Int(goal.currentValue)) \(unit)".trimmingCharacters(in: .whitespaces),
                    targetLabel: "\(Int(goal.targetValue ?? 0)) \(unit)".trimmingCharacters(in: .whitespaces)
                )
            }

            let tipVM = (try await tipTask).map { DashboardData.CoachTip(title: $0.title) }

            state = .loaded(DashboardData(
                unlockedAchievement: nil,   // TODO: último athlete_achievement
                wod: wodVM,
                attendedSessions: try await attendanceTask,
                prCount: try await prTask,
                nextGoal: goalVM,
                coachTip: tipVM,
                unreadCount: try await unreadTask
            ))
        } catch {
            state = .failed("No pudimos cargar tu inicio. Revisa tu conexión e inténtalo de nuevo.")
        }
    }
}

// MARK: - Skeleton de carga del dashboard

private struct DashboardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
            SkeletonBlock(height: 200, cornerRadius: NDCRadius.large) // WOD card
            HStack(spacing: NDCSpacing.gutter) {
                SkeletonBlock(height: 120, cornerRadius: NDCRadius.large)
                SkeletonBlock(height: 120, cornerRadius: NDCRadius.large)
            }
            SkeletonBlock(height: 110, cornerRadius: NDCRadius.large) // goal
            SkeletonBlock(height: 160, cornerRadius: NDCRadius.large) // tip
        }
    }
}

#Preview {
    AthleteDashboardView(profile: .preview)
}
