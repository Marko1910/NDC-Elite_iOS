import SwiftUI

/// TabView del COACH: Inicio · WODs · Atletas · Progreso · Perfil
/// Alertas se accede desde la campanita del Dashboard, no desde el tab bar.
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
            Tab("Progreso", systemImage: "chart.bar.fill") {
                CommunityProgressView(profile: profile)
            }
            Tab("Perfil", systemImage: "person.fill") {
                CoachProfileView(profile: profile)
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

// CommunityProgressView vive en CommunityProgressView.swift
