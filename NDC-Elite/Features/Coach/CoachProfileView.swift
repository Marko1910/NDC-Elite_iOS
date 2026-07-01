import SwiftUI

/// Tab 5 · Perfil del coach — cuenta, datos de contacto y cierre de sesión.
/// (ver FLOWS.md → CoachProfileView)
struct CoachProfileView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    idCard
                    accountSection
                    signOutButton
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackMD)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.large)
        }
        .tint(NDCColor.primary)
    }

    // MARK: - ID card

    private var idCard: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: profile.avatarURL, size: 88)
            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Text(profile.fullName)
                    .font(NDCFont.headlineMD)
                    .foregroundStyle(.white)
                Text(profile.role.displayName.uppercased())
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(NDCColor.accent, in: .capsule)
            }
            Spacer(minLength: 0)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.fullName), \(profile.role.displayName)")
    }

    // MARK: - Cuenta

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Cuenta")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            infoRow(icon: "phone.fill", title: "Teléfono", value: profile.phone ?? "Sin registrar")
            infoRow(icon: "calendar", title: "Miembro desde", value: memberSinceText)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: icon)
                .foregroundStyle(NDCColor.primary)
                .frame(width: 24)
            Text(title)
                .font(NDCFont.bodyMD)
                .foregroundStyle(NDCColor.onSurfaceVariant)
            Spacer()
            Text(value)
                .font(NDCFont.bodyMD.weight(.semibold))
                .foregroundStyle(NDCColor.onSurface)
        }
        .accessibilityElement(children: .combine)
    }

    private var memberSinceText: String {
        profile.memberSince.formatted(.dateTime.month(.wide).year())
    }

    // MARK: - Cerrar sesión

    private var signOutButton: some View {
        Button("Cerrar Sesión", role: .destructive) {
            Task { await session.signOut() }
        }
        .buttonStyle(.ndcGhost)
        .padding(.top, NDCSpacing.stackSM)
    }
}

#Preview {
    CoachProfileView(profile: .preview)
        .environment(SessionStore())
}
