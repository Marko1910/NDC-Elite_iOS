import SwiftUI

/// Invitar Atleta - Modal Coach — diseño Stitch "Invitar Atleta".
/// Sheet desde Gestión de Atletas. Comunidad cerrada: el atleta recibe una
/// invitación por correo para crear su cuenta. Nombre · correo · teléfono ·
/// nivel inicial · asignarme como coach. (ver FLOWS.md → InviteAthleteSheet)
///
/// TODO(datos): al enviar, usar Auth admin invite por email + crear profiles
/// con phone y nivel; asignar coach.
struct InviteAthleteView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var level: AthleteLevel = .basico
    @State private var assignSelf = true

    private var canSend: Bool { !name.isEmpty && email.contains("@") }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Label("NDC HQ es una comunidad cerrada. El atleta recibirá una invitación por correo para crear su cuenta.", systemImage: "lock.fill")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.onSurfaceVariant)
                        .padding(NDCSpacing.gutter)
                        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))

                    field("Nombre completo") {
                        TextField("Ej: Sofía Martínez", text: $name).textContentType(.name)
                    }
                    field("Correo electrónico") {
                        TextField("correo@ejemplo.com", text: $email)
                            .textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                    }
                    field("Teléfono") {
                        HStack(spacing: NDCSpacing.stackSM) {
                            Text("+51").foregroundStyle(NDCColor.outline)
                            TextField("987 654 321", text: $phone).keyboardType(.phonePad)
                        }
                    }
                    Label("Se usará para recordatorios por WhatsApp", systemImage: "info.circle")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)

                    VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                        Text("NIVEL INICIAL").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                        HStack(spacing: NDCSpacing.stackSM) {
                            ForEach(AthleteLevel.allCases, id: \.self) { lvl in
                                Button {
                                    Haptics.selection(); level = lvl
                                } label: {
                                    Text(lvl.displayName)
                                        .font(NDCFont.labelBold)
                                        .foregroundStyle(level == lvl ? .white : NDCColor.primary)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(level == lvl ? NDCColor.primary : NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
                                }
                                .accessibilityAddTraits(level == lvl ? .isSelected : [])
                            }
                        }
                    }

                    Toggle(isOn: $assignSelf) {
                        Label("Asignarme como su coach", systemImage: "person.fill.checkmark")
                            .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                    }
                    .tint(NDCColor.primary)
                    .padding(NDCSpacing.gutter)
                    .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                }
                .padding(NDCSpacing.marginMain)
            }
            .background(NDCColor.background)
            .navigationTitle("Nuevo Atleta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.notify(.success)
                    // TODO: enviar invitación (Auth invite)
                    dismiss()
                } label: {
                    Label("Enviar Invitación", systemImage: "paperplane.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
                .disabled(!canSend).opacity(canSend ? 1 : 0.5)
                .padding(.horizontal, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackSM)
                .background(.ultraThinMaterial)
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG)
                .padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }
}

#Preview {
    InviteAthleteView()
}
