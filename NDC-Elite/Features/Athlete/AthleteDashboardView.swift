import SwiftUI

/// Tab 1 · Inicio del atleta — diseño Stitch "NDC HQ - Dashboard".
/// Estructura: saludo · logro desbloqueado · WOD del día · stats (asistencia/récords)
/// · próximo objetivo · tip del coach. (ver FLOWS.md → AthleteDashboardView)
///
/// TODO(datos): hoy usa `DashboardData.sample`. Conectar a Supabase:
/// wods (próximo), attendance (resumen mes), personal_records (conteo + último),
/// athlete_goals (objetivo principal), coach_tips (último tip).
struct AthleteDashboardView: View {
    let profile: Profile
    private let data = DashboardData.sample

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    greeting
                    if let achievement = data.unlockedAchievement {
                        PRAlertCard(text: achievement)
                    }
                    WODCard(wod: data.wod, onOpen: { /* TODO: → WodDetailView */ })
                    StatsRow(
                        attended: data.attendedSessions,
                        goal: profile.monthlyAttendanceGoal,
                        prCount: data.prCount
                    )
                    NextGoalCard(goal: data.nextGoal)
                    CoachTipCard(tip: data.coachTip, onPlay: { /* TODO: → ExerciseDetailView */ })
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, 96) // espacio para el FAB
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .overlay(alignment: .bottomTrailing) {
                bookClassFAB
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { brandLabel }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        // TODO: → AthleteNotificationsView
                    } label: {
                        Image(systemName: "bell")
                            .foregroundStyle(NDCColor.primary)
                            .symbolEffect(.bounce, value: data.unreadCount)
                    }
                    .accessibilityLabel("Notificaciones")
                    .accessibilityValue(data.unreadCount > 0 ? "\(data.unreadCount) sin leer" : "Sin novedades")
                }
            }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Barra de marca (avatar + NDC HQ)

    private var brandLabel: some View {
        HStack(spacing: NDCSpacing.stackSM) {
            AvatarView(urlString: profile.avatarURL, size: 32)
                .accessibilityHidden(true)
            Text("NDC HQ")
                .font(NDCFont.headlineMD)
                .foregroundStyle(NDCColor.primary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("NDC HQ")
        .accessibilityAddTraits(.isHeader)
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

    // MARK: - FAB "Reservar clase"

    private var bookClassFAB: some View {
        Button {
            Haptics.impact()
            // TODO: reservar una clase
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
        .accessibilityLabel("Reservar una clase")
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

// MARK: - Avatar reutilizable

private struct AvatarView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay(Circle().stroke(NDCColor.primary, lineWidth: 2))
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .foregroundStyle(NDCColor.primary)
            .frame(width: size, height: size)
            .background(NDCColor.surface)
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct DashboardData {
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
    let wod: WOD
    let attendedSessions: Int
    let prCount: Int
    let nextGoal: Goal
    let coachTip: CoachTip
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

#Preview {
    AthleteDashboardView(profile: .preview)
}
