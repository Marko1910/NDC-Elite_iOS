import SwiftUI

/// Control de Asistencia (coach) — diseño Stitch "Control de Asistencia".
/// Selector de día · resumen del día (registrados / %) · lista de atletas con
/// toggle presente/ausente · acceso a generar QR. Se llega desde Gestión de
/// Atletas ("Tomar Asistencia"). (ver FLOWS.md → AttendanceView)
///
/// TODO(datos): hoy usa `AttendanceControlData.sample`. Conectar a Supabase:
/// class_sessions + attendance (toggle actualiza status presente/ausente).
struct AttendanceControlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay = 1
    @State private var roster = AttendanceControlData.sample
    @State private var showQR = false

    private var presentCount: Int { roster.filter(\.isPresent).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    daySelector
                    daySummary
                    Text("Próxima Clase 07:00 AM").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                    ForEach($roster) { $athlete in
                        AttendanceToggleRow(athlete: $athlete)
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, 96)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Asistencia")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    Haptics.impact(); showQR = true
                } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 22, weight: .semibold)).foregroundStyle(NDCColor.primary)
                        .frame(width: 56, height: 56).background(NDCColor.accent, in: .circle)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                }
                .padding(.trailing, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackLG)
                .accessibilityLabel("Generar QR de asistencia")
            }
            .sheet(isPresented: $showQR) { GenerateQRView() }
        }
        .tint(NDCColor.primary)
    }

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(Array(AttendanceControlData.days.enumerated()), id: \.offset) { index, day in
                    Button {
                        Haptics.selection(); selectedDay = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(day.weekday).font(NDCFont.labelSM)
                            Text(day.number).font(NDCFont.headlineSM)
                        }
                        .foregroundStyle(selectedDay == index ? .white : NDCColor.primary)
                        .frame(width: 52, height: 64)
                        .background(selectedDay == index ? NDCColor.primary : NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                    }
                }
            }
        }
    }

    private var daySummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RESUMEN DEL DÍA").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(presentCount)").font(NDCFont.statsXL).foregroundStyle(.white)
                    Text("/ 50 atletas registrados").font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
                }
            }
            Spacer()
            Text("\(Int(Double(presentCount) / 50 * 100))%").font(NDCFont.displayLG).foregroundStyle(NDCColor.accent)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
    }
}

private struct AttendanceToggleRow: View {
    @Binding var athlete: AttendanceControlData.Athlete

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: nil, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("\(athlete.level) • 07:00 AM").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            Button {
                Haptics.selection()
                withAnimation(.snappy) { athlete.isPresent.toggle() }
            } label: {
                Label(athlete.isPresent ? "Presente" : "Ausente",
                      systemImage: athlete.isPresent ? "checkmark.circle.fill" : "circle")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(athlete.isPresent ? NDCColor.onAccent : NDCColor.outline)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background((athlete.isPresent ? NDCColor.accent : NDCColor.surface), in: .capsule)
            }
            .accessibilityLabel("\(athlete.name): \(athlete.isPresent ? "presente" : "ausente")")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }
}

private enum AttendanceControlData {
    struct Day { let weekday, number: String }
    struct Athlete: Identifiable { let id = UUID(); let name, level: String; var isPresent: Bool }

    static let days: [Day] = [
        Day(weekday: "LUN", number: "23"), Day(weekday: "MAR", number: "24"),
        Day(weekday: "MIÉ", number: "25"), Day(weekday: "JUE", number: "26"),
        Day(weekday: "VIE", number: "27"), Day(weekday: "SÁB", number: "28")
    ]
    static let sample: [Athlete] = [
        Athlete(name: "Valeria S.", level: "RX", isPresent: true),
        Athlete(name: "Carlos M.", level: "Escalado", isPresent: false),
        Athlete(name: "Mateo G.", level: "RX", isPresent: false),
        Athlete(name: "Elena R.", level: "Escalado", isPresent: true),
        Athlete(name: "Diego F.", level: "RX", isPresent: true)
    ]
}

#Preview {
    AttendanceControlView()
}
