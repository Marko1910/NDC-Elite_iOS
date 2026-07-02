import SwiftUI

/// Pantalla de Inicio de Sesión (diseño Stitch: "Inicio de Sesión - NDC HQ").
/// Comunidad cerrada: no hay registro abierto, el alta es por invitación del coach.
struct LoginView: View {
    @Environment(SessionStore.self) private var session

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var showRegister = false

    var body: some View {
        ScrollView {
            VStack(spacing: NDCSpacing.stackLG) {
                Spacer(minLength: 60)

                // Logo / marca
                VStack(spacing: NDCSpacing.stackMD) {
                    Image("NDCLogo")
                        .resizable()
                        .scaledToFill()
                        // El arte trae margen alrededor del logotipo: el ligero
                        // zoom del scaledToFill dentro del marco lo recorta.
                        .frame(width: 220, height: 160)
                        .clipShape(.rect(cornerRadius: NDCRadius.large))
                        .shadow(color: NDCColor.primaryDark.opacity(0.25), radius: 12, y: 6)
                        .accessibilityLabel("NDC — Tu mejor versión, todos los días")
                    Text("Bienvenido de vuelta")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, NDCSpacing.stackLG)

                // Formulario
                VStack(spacing: NDCSpacing.stackMD) {
                    TextField("Correo electrónico", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .ndcInputStyle()

                    HStack(spacing: NDCSpacing.stackSM) {
                        Group {
                            if showPassword {
                                TextField("Contraseña", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            } else {
                                SecureField("Contraseña", text: $password)
                            }
                        }
                        .textContentType(.password)

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(NDCColor.onSurfaceVariant)
                        }
                    }
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
