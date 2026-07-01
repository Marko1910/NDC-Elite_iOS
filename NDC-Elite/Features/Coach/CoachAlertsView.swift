import SwiftUI

/// Tab 4 · Alertas del coach — diseño Stitch "Alertas y Notificaciones - Coach".
/// Lista de alertas accionables: validaciones pendientes, lesiones reportadas,
/// baja asistencia y mensajes, con acciones contextuales (validar, contactar
/// por WhatsApp, responder). (ver FLOWS.md → CoachAlertsView)
///
/// TODO(datos): hoy usa `CoachAlertsData.sample`. Conectar a Supabase:
/// notifications (user_id = coach) + datos relacionados.
struct CoachAlertsView: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    private let alerts = CoachAlertsData.sample

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                    HStack {
                        Text("Notificaciones").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                        Spacer()
                        Button("Marcar leídas") {
                            Haptics.impact(.light)
                            // TODO: update notifications.is_read = true
                        }
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    }
                    ForEach(alerts) { alert in
                        AlertCard(alert: alert)
                    }
                    HStack {
                        Spacer()
                        Label("No hay más alertas recientes", systemImage: "clock.arrow.circlepath")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                        Spacer()
                    }
                    .padding(.top, NDCSpacing.stackMD)
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Alertas")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
            }
        }
        .tint(NDCColor.primary)
    }
}

// MARK: - Tarjeta de alerta

private struct AlertCard: View {
    let alert: CoachAlertsData.Alert

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(alignment: .top, spacing: NDCSpacing.gutter) {
                Image(systemName: alert.kind.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(alert.kind.tint)
                    .frame(width: 40, height: 40)
                    .background(alert.kind.tint.opacity(0.12), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(alert.kind.title).font(NDCFont.labelBold).foregroundStyle(alert.kind.tint)
                        Spacer()
                        Text(alert.time).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    Text(alert.body)
                        .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if !alert.actions.isEmpty {
                HStack(spacing: NDCSpacing.stackSM) {
                    ForEach(Array(alert.actions.enumerated()), id: \.offset) { _, action in
                        Button {
                            Haptics.impact()
                            action.run()
                        } label: {
                            Label(action.title, systemImage: action.icon)
                                .font(NDCFont.labelBold)
                                .foregroundStyle(action.prominent ? .white : NDCColor.primary)
                                .padding(.horizontal, NDCSpacing.gutter).padding(.vertical, 8)
                                .background(action.prominent ? NDCColor.primary : NDCColor.surface,
                                            in: .capsule)
                        }
                    }
                }
                .padding(.leading, 56)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(alert.kind.tint.opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(alert.kind.title). \(alert.body)")
    }
}

// MARK: - Datos de muestra

private enum CoachAlertsData {
    enum Kind {
        case validacion, lesion, asistencia, mensaje
        var title: String {
            switch self {
            case .validacion: "Validación Pendiente"
            case .lesion: "Alerta de Lesión"
            case .asistencia: "Baja Asistencia"
            case .mensaje: "Nuevo Mensaje"
            }
        }
        var icon: String {
            switch self {
            case .validacion: "dumbbell.fill"
            case .lesion: "exclamationmark.triangle.fill"
            case .asistencia: "person.3.fill"
            case .mensaje: "bubble.left.fill"
            }
        }
        var tint: Color {
            switch self {
            case .lesion: NDCColor.error
            case .asistencia: NDCColor.onAccent
            default: NDCColor.primary
            }
        }
    }
    struct Action { let title, icon: String; var prominent = false; let run: () -> Void }
    struct Alert: Identifiable {
        let id = UUID()
        let kind: Kind
        let time, body: String
        let actions: [Action]
    }

    static let sample: [Alert] = [
        Alert(kind: .validacion, time: "Hace 5 min",
              body: "Mateo Rodríguez ha registrado un nuevo PR en Back Squat (145kg). Revisar ahora.",
              actions: [Action(title: "Validar", icon: "checkmark", prominent: true, run: {}),
                        Action(title: "Detalles", icon: "chevron.right", run: {})]),
        Alert(kind: .lesion, time: "Hace 1 hora",
              body: "Carla Méndez ha reportado una molestia lumbar leve tras la sesión de ayer.",
              actions: [Action(title: "Contactar Atleta", icon: "message.fill", run: {
                  WhatsAppHelper.sendAbsenceReminder(phone: "+51987654322", athleteName: "Carla", absentDays: 0)
              })]),
        Alert(kind: .asistencia, time: "Hace 3 horas",
              body: "La clase de las 07:00 AM tiene solo 12/50 cupos llenos.",
              actions: []),
        Alert(kind: .mensaje, time: "Ayer",
              body: "\"Hola coach, ¿podríamos ajustar los pesos de la sesión de mañana? Siento un poco de fatiga...\"",
              actions: [Action(title: "Responder a Lucía Gómez", icon: "arrowshape.turn.up.left.fill", run: {})])
    ]
}

#Preview {
    CoachAlertsView(profile: .preview)
}
