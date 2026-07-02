import SwiftUI

/// TabView del ATLETA: Inicio · WOD · Progreso · Comunidad · Perfil
/// (ver FLOWS.md para el mapa completo de navegación).
struct AthleteTabView: View {
    let profile: Profile
    @State private var selection: AthleteTab = .inicio

    enum AthleteTab: Hashable { case inicio, wod, progreso, comunidad, perfil }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Inicio", systemImage: "house.fill", value: .inicio) {
                // "Ver WOD" lleva al tab WOD (es la vista del WOD del día).
                AthleteDashboardView(profile: profile, openWod: { selection = .wod })
            }
            Tab("WOD", systemImage: "dumbbell.fill", value: .wod) {
                WodDetailView(profile: profile)
            }
            Tab("Progreso", systemImage: "chart.line.uptrend.xyaxis", value: .progreso) {
                PerformanceView(profile: profile)
            }
            Tab("Comunidad", systemImage: "person.3.fill", value: .comunidad) {
                CommunityView(profile: profile)
            }
            Tab("Perfil", systemImage: "person.fill", value: .perfil) {
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
