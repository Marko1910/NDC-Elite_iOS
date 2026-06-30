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
                WodManagementView(profile: profile)
            }
            Tab("Atletas", systemImage: "person.3.fill") {
                AthleteManagementView(profile: profile)
            }
            Tab("Alertas", systemImage: "bell.fill") {
                CoachAlertsView(profile: profile)
            }
            Tab("Progreso", systemImage: "chart.bar.fill") {
                CommunityProgressPlaceholderView()
            }
        }
        .tint(NDCColor.primary)
    }
}

// MARK: - Placeholders (se reemplazan al construir cada feature)
// CoachDashboardView vive en CoachDashboardView.swift

// WodManagementView vive en WodManagementView.swift

// AthleteManagementView vive en AthleteManagementView.swift

// CoachAlertsView vive en CoachAlertsView.swift

struct CommunityProgressPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Progreso Comunitario",
            systemImage: "chart.bar.fill",
            description: Text("PRs globales y adherencia (FLOWS.md: CommunityProgressView)")
        )
    }
}
