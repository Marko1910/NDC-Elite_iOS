import SwiftUI

/// TabView del COACH: Inicio · WODs · Atletas · Alertas · Progreso
/// (ver FLOWS.md para el mapa completo de navegación).
struct CoachTabView: View {
    let profile: Profile

    var body: some View {
        TabView {
            Tab("Inicio", systemImage: "house.fill") {
                CoachDashboardView(profile: profile)
            }
            Tab("WODs", systemImage: "dumbbell.fill") {
                WodManagementPlaceholderView()
            }
            Tab("Atletas", systemImage: "person.3.fill") {
                AthleteManagementPlaceholderView()
            }
            Tab("Alertas", systemImage: "bell.fill") {
                CoachAlertsPlaceholderView()
            }
            Tab("Progreso", systemImage: "chart.bar.fill") {
                CommunityProgressPlaceholderView()
            }
        }
        .tint(NDCColor.primary)
    }
}

// MARK: - Placeholders (se reemplazan al construir cada feature)

struct CoachDashboardView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Text("¡Hola, Coach!")
                        .font(NDCFont.displayLG)
                        .foregroundStyle(NDCColor.onSurface)
                    Text("Resumen estratégico de hoy")
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.onSurfaceVariant)

                    NDCCard {
                        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                            NDCChip(text: "Acción Requerida", color: NDCColor.error)
                            Text("Próximamente: asistencia de hoy, validaciones pendientes y alertas")
                                .font(NDCFont.bodyMD)
                                .foregroundStyle(NDCColor.onSurfaceVariant)
                        }
                    }

                    Button("Cerrar Sesión", role: .destructive) {
                        Task { await session.signOut() }
                    }
                    .buttonStyle(.ndcGhost)
                }
                .padding(.horizontal, NDCSpacing.marginMain)
            }
            .background(NDCColor.background)
        }
    }
}

struct WodManagementPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Gestión de WODs",
            systemImage: "dumbbell.fill",
            description: Text("Programación semanal y editor (FLOWS.md: WodManagementView)")
        )
    }
}

struct AthleteManagementPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Gestión de Atletas",
            systemImage: "person.3.fill",
            description: Text("Atletas, asistencia y perfiles (FLOWS.md: AthleteManagementView)")
        )
    }
}

struct CoachAlertsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Alertas",
            systemImage: "bell.fill",
            description: Text("Validaciones, lesiones y asistencia (FLOWS.md: CoachAlertsView)")
        )
    }
}

struct CommunityProgressPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Progreso Comunitario",
            systemImage: "chart.bar.fill",
            description: Text("PRs globales y adherencia (FLOWS.md: CommunityProgressView)")
        )
    }
}
