import SwiftUI
import PhotosUI
import UIKit

/// Tab 5 · Perfil del coach — cuenta, datos de contacto y cierre de sesión.
/// El coach puede editar su nombre y foto; el cambio se refleja de inmediato
/// en el saludo del Dashboard y en el resto de la app (SessionStore).
/// (ver FLOWS.md → CoachProfileView)
struct CoachProfileView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var isUploadingPhoto = false
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var errorMessage: String?
    private let repo = ProfileRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    idCard
                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
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
            .alert("Editar nombre", isPresented: $isEditingName) {
                TextField("Nombre completo", text: $editedName)
                Button("Cancelar", role: .cancel) {}
                Button("Guardar") { Task { await saveName() } }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                guard let newValue else { return }
                Task { await uploadPhoto(newValue) }
            }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - ID card

    private var idCard: some View {
        HStack(spacing: NDCSpacing.gutter) {
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    NDCAvatarView(urlString: profile.avatarURL, size: 88)
                    if isUploadingPhoto {
                        Circle().fill(.black.opacity(0.4)).frame(width: 88, height: 88)
                        ProgressView().tint(.white)
                    } else {
                        Circle().fill(.black.opacity(0.35)).frame(width: 26, height: 26)
                            .overlay(Image(systemName: "camera.fill").font(.system(size: 12)).foregroundStyle(.white))
                            .offset(x: 30, y: 30)
                    }
                }
            }
            .disabled(isUploadingPhoto)
            .accessibilityLabel("Cambiar foto de perfil")

            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Button {
                    editedName = profile.fullName
                    isEditingName = true
                } label: {
                    HStack(spacing: 6) {
                        Text(profile.fullName)
                            .font(NDCFont.headlineMD)
                            .foregroundStyle(.white)
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .accessibilityLabel("Editar nombre, actual: \(profile.fullName)")
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

    // MARK: - Edición

    private func saveName() async {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != profile.fullName else { return }
        do {
            try await repo.updateFullName(userId: profile.id, name: trimmed)
            var updated = profile
            updated.fullName = trimmed
            session.updateLocalProfile(updated)
        } catch {
            errorMessage = "No se pudo actualizar el nombre. Intenta de nuevo."
        }
    }

    private func uploadPhoto(_ item: PhotosPickerItem) async {
        errorMessage = nil
        isUploadingPhoto = true
        defer { isUploadingPhoto = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let jpegData = uiImage.jpegData(compressionQuality: 0.8) else {
                errorMessage = "No se pudo leer la imagen seleccionada."
                return
            }
            let url = try await repo.uploadAvatar(userId: profile.id, imageData: jpegData)
            var updated = profile
            updated.avatarURL = url
            session.updateLocalProfile(updated)
        } catch {
            errorMessage = "No se pudo subir la foto. Intenta de nuevo."
        }
    }
}

#Preview {
    CoachProfileView(profile: .preview)
        .environment(SessionStore())
}
