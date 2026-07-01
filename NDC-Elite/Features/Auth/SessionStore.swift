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

    /// Registro de atleta con código de invitación (comunidad cerrada).
    /// Valida el código → crea la cuenta → canjea el código. Devuelve true si OK.
    func register(name: String, email: String, phone: String,
                  password: String, inviteCode: String) async -> Bool {
        errorMessage = nil
        let code = inviteCode.trimmingCharacters(in: .whitespaces).uppercased()
        do {
            // 1) ¿Código válido y disponible? (RPC pública)
            let valid: Bool = try await client.rpc("invitation_code_valid", params: ["p_code": code])
                .execute().value
            guard valid else {
                errorMessage = "Código de invitación inválido o ya usado. Pídele uno a tu coach."
                return false
            }
            // 2) Crear cuenta
            try await client.auth.signUp(
                email: email, password: password,
                data: ["full_name": .string(name)])
            // 3) Guardar teléfono y canjear el código (ya autenticado)
            if let uid = client.auth.currentSession?.user.id {
                try? await client.from("profiles")
                    .update(["phone": phone]).eq("id", value: uid).execute()
            }
            // redeem_role_code marca el código usado y, si es de tipo 'coach',
            // sube el rol del perfil recién creado (ver migración 14).
            let redeemed: Bool = try await client.rpc("redeem_role_code", params: ["p_code": code])
                .execute().value
            if !redeemed { /* el código se tomó entre validar y canjear; cuenta creada igual */ }
            return true
        } catch {
            errorMessage = "No se pudo crear la cuenta. Verifica el correo (¿ya registrado?) e inténtalo de nuevo."
            return false
        }
    }

    /// Registro del primer coach (fundador), sin código de invitación. Solo
    /// concede el rol si todavía no existe ningún coach (lo valida el trigger
    /// `handle_new_user` en el servidor; si ya hay uno, la cuenta se crea igual
    /// pero como atleta).
    func registerFoundingCoach(name: String, email: String, phone: String, password: String) async -> Bool {
        errorMessage = nil
        do {
            try await client.auth.signUp(
                email: email, password: password,
                data: ["full_name": .string(name), "requested_role": .string("coach")])
            if let uid = client.auth.currentSession?.user.id {
                try? await client.from("profiles")
                    .update(["phone": phone]).eq("id", value: uid).execute()
            }
            return true
        } catch {
            errorMessage = "No se pudo crear la cuenta. Verifica el correo (¿ya registrado?) e inténtalo de nuevo."
            return false
        }
    }

    /// ¿Ya existe algún coach? Determina si el registro debe ofrecer la opción
    /// de "coach fundador". Ante cualquier duda (RPC aún no desplegada, sin
    /// red) asume que sí existe, para no exponer la opción de más.
    func anyCoachExists() async -> Bool {
        (try? await client.rpc("any_coach_exists").execute().value) ?? true
    }

    func signOut() async {
        try? await client.auth.signOut()
        state = .loggedOut
    }

    /// Refresca el perfil en memoria tras una edición (nombre, foto), para que
    /// el saludo y el resto de la app se actualicen sin esperar un relogin.
    func updateLocalProfile(_ profile: Profile) {
        state = .loggedIn(profile)
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
