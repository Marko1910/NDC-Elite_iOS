import SwiftUI

/// TabView del ATLETA: Inicio · WOD · Progreso · Comunidad · Perfil
/// (ver FLOWS.md para el mapa completo de navegación).
struct AthleteTabView: View {
    let profile: Profile

    var body: some View {
        TabView {
            Tab("Inicio", systemImage: "house.fill") {
                AthleteDashboardView(profile: profile)
            }
            Tab("WOD", systemImage: "dumbbell.fill") {
                WodDetailView(profile: profile)
            }
            Tab("Progreso", systemImage: "chart.line.uptrend.xyaxis") {
                PerformanceView(profile: profile)
            }
            Tab("Comunidad", systemImage: "person.3.fill") {
                CommunityView(profile: profile)
            }
            Tab("Perfil", systemImage: "person.fill") {
                AthleteProfileView(profile: profile)
            }
        }
        .tint(NDCColor.primary)
    }
}

// MARK: - Placeholders (se reemplazan al construir cada feature)
// AthleteDashboardView vive en AthleteDashboardView.swift
// WodDetailView vive en WodDetailView.swift
// PerformanceView vive en PerformanceView.swift
// AthleteProfileView vive en AthleteProfileView.swift
// CommunityView vive en CommunityView.swift
