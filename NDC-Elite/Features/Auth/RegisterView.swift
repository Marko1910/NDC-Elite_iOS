import SwiftUI

/// Registro de Atleta - NDC HQ — diseño Stitch "Registro de Atleta".
/// Comunidad cerrada: el alta requiere un **código de invitación** que entrega
/// el coach. Campos: nombre · correo · celular · contraseña · código.
/// (ver FLOWS.md / NAVIGATION.md — Login ↔ Registro)
struct RegisterView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isLoading = false
    @State private var anyCoachExists = true
    @State private var registerAsFoundingCoach = false

    private var canSubmit: Bool {
        let base = !name.isEmpty && email.contains("@") && password.count >= 6
        return registerAsFoundingCoach ? base : (base && !code.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: NDCSpacing.stackLG) {
                VStack(spacing: NDCSpacing.stackSM) {
                    Text("Únete a la Élite")
                        .font(NDCFont.displayLG).foregroundStyle(NDCColor.primaryDark)
                    Text("Completa tu registro para acceder a NDC HQ.")
                        .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, NDCSpacing.stackLG)

                VStack(spacing: NDCSpacing.stackMD) {
                    field("Nombre completo") {
                        TextField("Ej. Juan Pérez", text: $name).textContentType(.name)
                    }
                    field("Correo electrónico") {
                        TextField("juan@ejemplo.com", text: $email)
                            .textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    field("Número de celular") {
                        TextField("+51 987 654 321", text: $phone).keyboardType(.phonePad)
                    }
                    field("Contraseña") {
                        SecureField("Mínimo 6 caracteres", text: $password).textContentType(.newPassword)
                    }
                    if !anyCoachExists {
                        founderToggle
                    }
                    if !registerAsFoundingCoach {
                        inviteCodeField
                    }

                    if let error = session.errorMessage {
                        Text(error).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            isLoading = true
                            let ok = registerAsFoundingCoach
                                ? await session.registerFoundingCoach(name: name, email: email, phone: phone, password: password)
                                : await session.register(name: name, email: email, phone: phone,
                                                          password: password, inviteCode: code)
                            isLoading = false
                            if ok { dismiss() } // authStateChanges enruta a los tabs
                        }
                    } label: {
                        if isLoading { ProgressView().tint(.white) }
                        else { Text("Crear Cuenta") }
                    }
                    .buttonStyle(.ndcPrimary)
                    .disabled(!canSubmit || isLoading)

                    Button("¿Ya tienes cuenta? Iniciar Sesión") { dismiss() }
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollDismissesKeyboard(.interactively)
        .task { anyCoachExists = await session.anyCoachExists() }
    }

    private var founderToggle: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Toggle(isOn: $registerAsFoundingCoach) {
                Label("Registrarme como Coach Fundador", systemImage: "star.fill")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurfaceVariant)
            }
            .tint(NDCColor.primary)
            Text("Aún no hay ningún coach en NDC HQ. Esta opción solo aparece la primera vez.")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
        }
        .padding(14)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
    }

    private var inviteCodeField: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack(spacing: 4) {
                Image(systemName: "key.fill").font(.system(size: 12)).foregroundStyle(NDCColor.onAccent)
                Text("Código de Invitación").font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurfaceVariant)
                Text("*").foregroundStyle(NDCColor.error)
            }
            TextField("INGRESA EL CÓDIGO", text: $code)
                .font(NDCFont.bodyLG.weight(.bold))
                .textInputAutocapitalization(.characters).autocorrectionDisabled()
                .padding(14)
                .background(NDCColor.accent.opacity(0.12), in: .rect(cornerRadius: NDCRadius.standard))
                .overlay(RoundedRectangle(cornerRadius: NDCRadius.standard).stroke(NDCColor.accent, lineWidth: 1))
            Text("Este código es proporcionado exclusivamente por tu coach.")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
        }
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurfaceVariant)
            content()
                .font(NDCFont.bodyLG).padding(14)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    RegisterView().environment(SessionStore())
}
