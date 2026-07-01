import SwiftUI

/// Pantalla de Inicio de Sesión (diseño Stitch: "Inicio de Sesión - NDC HQ").
/// Comunidad cerrada: no hay registro abierto, el alta es por invitación del coach.
struct LoginView: View {
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showRegister = false

    var body: some View {
        ScrollView {
            VStack(spacing: NDCSpacing.stackLG) {
                Spacer(minLength: 60)

                // Logo / marca
                VStack(spacing: NDCSpacing.stackSM) {
                    Text("NDC HQ")
                        .font(NDCFont.displayLG)
                        .foregroundStyle(NDCColor.primaryDark)
                    Text("Bienvenido de vuelta")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
                .padding(.bottom, NDCSpacing.stackLG)

                // Formulario
                VStack(spacing: NDCSpacing.stackMD) {
                    TextField("Correo electrónico", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .ndcInputStyle()

                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                        .ndcInputStyle()

                    if let error = session.errorMessage {
                        Text(error)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            isLoading = true
                            await session.signIn(email: email, password: password)
                            isLoading = false
                        }
                    } label: {
                        if isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Iniciar Sesión")
                        }
                    }
                    .buttonStyle(.ndcPrimary)
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                }

                Spacer(minLength: 40)

                // Nota de comunidad cerrada
                HStack(spacing: NDCSpacing.stackSM) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                    Text("NDC HQ es una comunidad cerrada. Si aún no tienes cuenta, solicita una invitación a tu coach.")
                        .font(NDCFont.labelSM)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))

                // ¿No tienes cuenta? Regístrate
                HStack(spacing: 4) {
                    Text("¿No tienes cuenta?")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurfaceVariant)
                    Button("Regístrate") { showRegister = true }
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
        }
        .background(NDCColor.background)
        .sheet(isPresented: $showRegister) {
            RegisterView().environment(session)
        }
    }
}

/// Estilo de input del design system: fondo gris suave, radio 8, texto 17pt
/// (17pt evita el auto-zoom de iOS al enfocar).
private struct NDCInputModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(NDCFont.bodyLG)
            .padding(14)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
    }
}

extension View {
    func ndcInputStyle() -> some View { modifier(NDCInputModifier()) }
}

#Preview {
    LoginView().environment(SessionStore())
}
