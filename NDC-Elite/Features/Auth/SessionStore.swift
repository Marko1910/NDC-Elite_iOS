import Foundation
import Supabase

/// Estado global de sesión: escucha los cambios de auth de Supabase
/// y carga el perfil (con su rol) para enrutar atleta vs coach.
@MainActor
@Observable
final class SessionStore {
    enum State {
        case loading
        case loggedOut
        case loggedIn(Profile)
    }

    private(set) var state: State = .loading
    var errorMessage: String?

    private let client = SupabaseManager.client

    /// Llamar al lanzar la app: restaura sesión existente y escucha cambios.
    func start() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed:
                if let session {
                    await loadProfile(userId: session.user.id)
                } else {
                    state = .loggedOut
                }
            case .signedOut:
                state = .loggedOut
            default:
                break
            }
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        do {
            try await client.auth.signIn(email: email, password: password)
            // authStateChanges se encarga de cargar el perfil
        } catch {
            errorMessage = "Credenciales incorrectas. Verifica tu correo y contraseña."
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        state = .loggedOut
    }

    private func loadProfile(userId: UUID) async {
        // Tras `signIn`, el SDK puede tardar un instante en dejar la sesión lista
        // para PostgREST; si la primera consulta llega sin token (RLS → 0 filas),
        // reintentamos brevemente. Cubre login real y restauración de sesión.
        for attempt in 0..<4 {
            do {
                let profile: Profile = try await client
                    .from("profiles")
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                state = .loggedIn(profile)
                return
            } catch {
                if attempt < 3 {
                    try? await Task.sleep(for: .milliseconds(250))
                    continue
                }
                errorMessage = "No se pudo cargar tu perfil. Intenta de nuevo."
                state = .loggedOut
            }
        }
    }
}
