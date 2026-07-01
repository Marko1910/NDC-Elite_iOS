import SwiftUI
import Supabase

/// Generar Código de Invitación - Coach — diseño Stitch.
/// El coach genera un código único de acceso, lo comparte con el atleta (o con
/// un futuro coach) y ve sus códigos activos. (ver NAVIGATION.md)
///
/// Persiste en `invitation_codes` (created_by = coach, role = atleta|coach).
/// Quien lo canjea usa `redeem_role_code`, que sube su rol si el código es de
/// tipo coach.
struct GenerateInviteCodeView: View {
    @Environment(\.dismiss) private var dismiss
    private let client = SupabaseManager.client

    @State private var currentCode = ""
    @State private var role: UserRole = .atleta
    @State private var active: [InviteCode] = []
    @State private var isWorking = false

    struct InviteCode: Identifiable, Decodable {
        var id: UUID
        var code: String
        var createdAt: Date
        var usedBy: UUID?
        var role: UserRole
        enum CodingKeys: String, CodingKey { case id, code, role; case createdAt = "created_at"; case usedBy = "used_by" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NDCSpacing.stackLG) {
                    Text("Genera un código de acceso único para invitar a un nuevo atleta —o a un nuevo coach— a unirse a NDC HQ.")
                        .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                        .multilineTextAlignment(.center)

                    rolePicker
                    codeCard
                    shareButton
                    activeCodesSection
                }
                .padding(NDCSpacing.marginMain)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Invitar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .task {
                if currentCode.isEmpty { currentCode = Self.newCode() }
                await loadActive()
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private var rolePicker: some View {
        Picker("Tipo de código", selection: $role) {
            Text("Atleta").tag(UserRole.atleta)
            Text("Coach").tag(UserRole.coach)
        }
        .pickerStyle(.segmented)
    }

    private var codeCard: some View {
        VStack(spacing: NDCSpacing.stackMD) {
            Text(role == .coach ? "CÓDIGO DE COACH" : "CÓDIGO DE ACCESO")
                .font(NDCFont.labelBold).foregroundStyle(NDCColor.outline).tracking(1)
            Text(currentCode).font(.system(size: 38, weight: .heavy, design: .rounded)).foregroundStyle(NDCColor.primaryDark)
            Button {
                Haptics.impact(); currentCode = Self.newCode()
            } label: {
                Label("Generar nuevo código", systemImage: "arrow.clockwise")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    .padding(.horizontal, NDCSpacing.gutter).padding(.vertical, 8)
                    .overlay(Capsule().stroke(NDCColor.outline.opacity(0.4), lineWidth: 1))
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [NDCColor.accent.opacity(0.18), NDCColor.surface],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: .rect(cornerRadius: NDCRadius.large))
    }

    private var shareButton: some View {
        Button {
            Task { await saveAndShare() }
        } label: {
            Label(isWorking ? "Guardando…" : "Enviar a Atleta", systemImage: "square.and.arrow.up")
                .font(NDCFont.headlineSM).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        }
        .disabled(isWorking)
    }

    private var activeCodesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Códigos Activos").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Text("\(active.count) Pendientes").font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(NDCColor.accent, in: .capsule)
            }
            if active.isEmpty {
                Text("Aún no hay códigos pendientes.").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            } else {
                ForEach(active) { item in
                    HStack(spacing: NDCSpacing.gutter) {
                        Image(systemName: "person.badge.key.fill").foregroundStyle(NDCColor.primary)
                            .frame(width: 40, height: 40).background(NDCColor.surface, in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(item.code).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                                if item.role == .coach {
                                    NDCChip(text: "Coach")
                                }
                            }
                            Text(item.createdAt, format: .dateTime.day().month().hour().minute())
                                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                        }
                        Spacer()
                        Button { Task { await deleteCode(item) } } label: {
                            Image(systemName: "trash").foregroundStyle(NDCColor.error)
                        }
                        .accessibilityLabel("Eliminar código \(item.code)")
                    }
                    .padding(NDCSpacing.gutter)
                    .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
                    .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Datos

    private func loadActive() async {
        // Reintento breve por si la sesión aún no está lista para PostgREST.
        for attempt in 0..<3 {
            do {
                active = try await client.from("invitation_codes")
                    .select().is("used_by", value: nil)
                    .order("created_at", ascending: false)
                    .execute().value
                return
            } catch {
                if attempt < 2 { try? await Task.sleep(for: .milliseconds(300)) }
            }
        }
    }

    private func saveAndShare() async {
        isWorking = true
        defer { isWorking = false }
        do {
            guard let uid = client.auth.currentSession?.user.id else { return }
            try await client.from("invitation_codes")
                .insert(["code": currentCode, "created_by": uid.uuidString, "role": role.rawValue]).execute()
            Haptics.notify(.success)
            await loadActive()
            await MainActor.run { shareSheet(text: shareMessage) }
            currentCode = Self.newCode()
        } catch {
            Haptics.notify(.error)
        }
    }

    private func deleteCode(_ item: InviteCode) async {
        do {
            try await client.from("invitation_codes").delete().eq("id", value: item.id).execute()
            Haptics.impact(.light)
            await loadActive()
        } catch {}
    }

    private var shareMessage: String {
        role == .coach
            ? "¡Bienvenido a NDC HQ como coach! 💪 Regístrate en la app con este código de invitación: \(currentCode)"
            : "¡Bienvenido a NDC HQ! 💪 Regístrate en la app con este código de invitación: \(currentCode)"
    }

    private func shareSheet(text: String) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        root.present(av, animated: true)
    }

    static func newCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let suffix = String((0..<4).map { _ in chars.randomElement()! })
        return "NDC-\(suffix)"
    }
}

#Preview {
    GenerateInviteCodeView()
}
