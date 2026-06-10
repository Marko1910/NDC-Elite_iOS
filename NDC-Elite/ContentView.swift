import SwiftUI

/// Router raíz: decide qué mostrar según el estado de sesión y el rol del perfil.
/// loading → splash · loggedOut → Login · atleta → tabs atleta · coach → tabs coach
struct ContentView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        switch session.state {
        case .loading:
            VStack(spacing: NDCSpacing.stackMD) {
                Text("NDC HQ")
                    .font(NDCFont.displayLG)
                    .foregroundStyle(NDCColor.primaryDark)
                ProgressView()
            }
        case .loggedOut:
            LoginView()
        case .loggedIn(let profile):
            switch profile.role {
            case .atleta:
                AthleteTabView(profile: profile)
            case .coach, .admin:
                CoachTabView(profile: profile)
            }
        }
    }
}

#Preview {
    ContentView().environment(SessionStore())
}
