import SwiftUI

/// Bandeja de notificaciones del atleta — se abre desde la campanita del
/// Inicio. Lista las notificaciones reales (`notifications`) y las marca
/// como leídas al abrirse.
struct AthleteNotificationsView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    @State private var state: LoadState<[AppNotification]> = .loading
    private let repo = AthleteRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                LoadStateView(state: state, retry: { Task { await load() } }) { items in
                    if items.isEmpty {
                        ContentUnavailableView(
                            "Sin notificaciones",
                            systemImage: "bell.slash",
                            description: Text("Aquí verás validaciones, logros y avisos de tu coach.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        VStack(spacing: NDCSpacing.stackSM) {
                            ForEach(items) { item in
                                NotificationRow(item: item)
                            }
                        }
                        .padding(NDCSpacing.marginMain)
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackSM) {
                        SkeletonCard(lines: 2, height: 70)
                        SkeletonCard(lines: 2, height: 70)
                        SkeletonCard(lines: 2, height: 70)
                    }
                    .padding(NDCSpacing.marginMain)
                }
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
            }
            .task { await load() }
            .refreshable { await load() }
        }
        .tint(NDCColor.primary)
    }

    private func load() async {
        do {
            let items = try await repo.notifications(userId: profile.id)
            state = .loaded(items)
            // Al ver la bandeja, todo queda leído (apaga el badge de la campana).
            try? await repo.markNotificationsRead(userId: profile.id)
        } catch {
            state = .failed("No se pudieron cargar las notificaciones.")
        }
    }
}

private struct NotificationRow: View {
    let item: AppNotification

    private var icon: String {
        switch item.type {
        case .validacion: "checkmark.seal.fill"
        case .lesion: "cross.case.fill"
        case .asistencia: "calendar.badge.checkmark"
        case .mensaje: "bubble.left.fill"
        case .logro: "star.fill"
        case .general: "bell.fill"
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: NDCSpacing.gutter) {
            Image(systemName: icon)
                .foregroundStyle(item.isRead ? NDCColor.outline : NDCColor.primary)
                .frame(width: 40, height: 40)
                .background((item.isRead ? NDCColor.outline : NDCColor.primary).opacity(0.1), in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(item.isRead ? NDCFont.bodyMD : NDCFont.bodyMD.weight(.bold))
                    .foregroundStyle(NDCColor.onSurface)
                if let body = item.body, !body.isEmpty {
                    Text(body).font(NDCFont.labelSM).foregroundStyle(NDCColor.onSurfaceVariant)
                }
                Text(item.createdAt, format: .relative(presentation: .named))
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer(minLength: 0)
            if !item.isRead {
                Circle().fill(NDCColor.accent).frame(width: 10, height: 10)
                    .padding(.top, 6)
            }
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AthleteNotificationsView(profile: .preview)
}
