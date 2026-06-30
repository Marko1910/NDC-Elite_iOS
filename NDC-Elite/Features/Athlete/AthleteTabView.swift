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
                CommunityPlaceholderView()
            }
            Tab("Perfil", systemImage: "person.fill") {
                AthleteProfilePlaceholderView(profile: profile)
            }
        }
        .tint(NDCColor.primary)
    }
}

// MARK: - Placeholders (se reemplazan al construir cada feature)
// AthleteDashboardView vive en AthleteDashboardView.swift
// WodDetailView vive en WodDetailView.swift
// PerformanceView vive en PerformanceView.swift

struct CommunityPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "Comunidad",
            systemImage: "person.3.fill",
            description: Text("Retos y ranking (FLOWS.md: CommunityView)")
        )
    }
}

struct AthleteProfilePlaceholderView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Nombre", value: profile.fullName)
                    LabeledContent("Nivel", value: profile.level.displayName)
                    LabeledContent("Puntos", value: "\(profile.points)")
                }
                Section {
                    Button("Cerrar Sesión", role: .destructive) {
                        Task { await session.signOut() }
                    }
                }
            }
            .navigationTitle("Perfil")
        }
    }
}
