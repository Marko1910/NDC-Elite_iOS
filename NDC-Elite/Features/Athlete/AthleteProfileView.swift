import SwiftUI
import Charts

/// Tab 5 · Perfil del atleta — diseño Stitch "Perfil de Atleta - Con Registro de
/// Lesiones". ID card · bento (asistencia/peso/racha) · meta principal ·
/// historial de marcas con **sparklines reales (Swift Charts)** · notas médicas ·
/// registro de lesiones (+ Registrar Nueva Lesión). (ver FLOWS.md → AthleteProfileView)
///
/// TODO(datos): usa `ProfileData.sample` salvo lo que viene de `profile`.
/// Conectar a Supabase: attendance (resumen), personal_records (historial),
/// athlete_goals (meta), coach_notes (notas), injuries (lista).
struct AthleteProfileView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session
    private let data = ProfileData.sample

    @State private var showLogInjury = false
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    idCard
                    bentoRow
                    mainGoal
                    marksHistory
                    medicalNotes
                    injuriesSection
                    signOutButton
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackMD)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationDestination(isPresented: $showLogInjury) {
                LogInjuryView()
            }
            .fullScreenCover(isPresented: $showScanner) {
                AttendanceScannerView()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NDCBrandLabel(avatarURL: profile.avatarURL)
                }
                // Escáner QR de asistencia (en lugar de la campana).
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.impact(.light)
                        showScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Escanear QR de asistencia")
                }
            }
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
                HStack(spacing: NDCSpacing.stackSM) {
                    Text("Nivel \(profile.level.displayName)")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.onAccent)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(NDCColor.accent, in: .capsule)
                    Text("Desde \(memberSinceYear)")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(.white.opacity(0.12), in: .capsule)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .shadow(color: NDCColor.primaryDark.opacity(0.15), radius: 10, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.fullName), nivel \(profile.level.displayName), desde \(memberSinceYear)")
    }

    private var memberSinceYear: String {
        Calendar.current.component(.year, from: profile.memberSince).description
    }

    // MARK: - Bento biométrico

    private var bentoRow: some View {
        VStack(spacing: NDCSpacing.gutter) {
            // Asistencia (ancho completo)
            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Text("ASISTENCIA MENSUAL")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(data.attended)")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(NDCColor.primary)
                    Text("/ \(data.monthlyTotal)")
                        .font(NDCFont.bodyLG)
                        .foregroundStyle(NDCColor.outline)
                }
                ProgressBar(value: Double(data.attended) / Double(data.monthlyTotal))
                HStack {
                    Text("Objetivo: \(profile.monthlyAttendanceGoal)")
                    Spacer()
                    if data.attended > profile.monthlyAttendanceGoal {
                        Text("+\(data.attended - profile.monthlyAttendanceGoal) sobre meta")
                            .foregroundStyle(NDCColor.primary)
                    }
                }
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.outline)
            }
            .padding(NDCSpacing.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardBorder()

            HStack(spacing: NDCSpacing.gutter) {
                miniMetric(title: "PESO", value: "\(formatted(profile.weightKg ?? 0))",
                           unit: "kg", icon: "arrow.down", note: data.weightDelta)
                miniMetric(title: "RACHA", value: "\(profile.streakDays)",
                           unit: "días", icon: "flame.fill", note: "Personal Best")
            }
        }
    }

    private func miniMetric(title: String, value: String, unit: String, icon: String, note: String) -> some View {
        VStack(spacing: NDCSpacing.stackSM) {
            Text(title).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                Text(unit).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Label(note, systemImage: icon)
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(NDCSpacing.gutter)
        .cardBorder()
    }

    // MARK: - Meta principal

    private var mainGoal: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Label("Meta Principal", systemImage: "flag.fill")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.onSurface)
                Spacer()
                Text("\(Int(data.goalProgress * 100))% Completado")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
            Text(data.goalTitle)
                .font(NDCFont.bodyMD)
                .foregroundStyle(NDCColor.onSurfaceVariant)
            ProgressBar(value: data.goalProgress, height: 10)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBorder()
    }

    // MARK: - Historial de marcas (sparklines reales)

    private var marksHistory: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Historial de Marcas (PR)")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            VStack(spacing: NDCSpacing.gutter) {
                ForEach(data.prHistory) { pr in
                    PRSparklineCard(pr: pr)
                }
            }
        }
    }

    // MARK: - Notas médicas

    private var medicalNotes: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label("Notas Médicas y Limitaciones", systemImage: "cross.case.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            ForEach(data.medicalNotes) { note in
                HStack(alignment: .top, spacing: NDCSpacing.stackSM) {
                    Image(systemName: note.isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .foregroundStyle(note.isWarning ? NDCColor.error : NDCColor.primary)
                    Text(note.text)
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(NDCColor.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    // MARK: - Lesiones

    private var injuriesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label("Registro de Lesiones y Preocupaciones", systemImage: "bandage.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            ForEach(data.injuries) { injury in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(injury.name)
                            .font(NDCFont.bodyMD)
                            .foregroundStyle(NDCColor.onSurface)
                        Text(injury.status.uppercased())
                            .font(NDCFont.labelSM)
                            .foregroundStyle(NDCColor.outline)
                    }
                    Spacer()
                    Text(injury.severity.uppercased())
                        .font(NDCFont.labelBold)
                        .foregroundStyle(injury.isModerate ? NDCColor.error : NDCColor.onAccent)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background((injury.isModerate ? NDCColor.error : NDCColor.accent).opacity(0.18),
                                    in: .capsule)
                }
                .padding(NDCSpacing.gutter)
                .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.standard))
                .accessibilityElement(children: .combine)
            }
            Button {
                Haptics.impact()
                showLogInjury = true
            } label: {
                Label("Registrar Nueva Lesión", systemImage: "plus.circle.fill")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    // MARK: - Cerrar sesión

    private var signOutButton: some View {
        Button("Cerrar Sesión", role: .destructive) {
            Task { await session.signOut() }
        }
        .buttonStyle(.ndcGhost)
        .padding(.top, NDCSpacing.stackSM)
    }

    private func formatted(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Barra de progreso reutilizable

private struct ProgressBar: View {
    let value: Double
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(NDCColor.surfaceStrong)
                Capsule().fill(NDCColor.primary)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Tarjeta de PR con sparkline real (Swift Charts)

private struct PRSparklineCard: View {
    let pr: ProfileData.PRMark

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pr.exercise.uppercased())
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(Int(pr.value))").font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
                    Text("kg").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
                Text(pr.ago).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            // Gráfica real, alimentada por el historial del PR
            Chart {
                ForEach(Array(pr.history.enumerated()), id: \.offset) { index, v in
                    LineMark(x: .value("i", index), y: .value("kg", v))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(NDCColor.primary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    AreaMark(x: .value("i", index), y: .value("kg", v))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.linearGradient(
                            colors: [NDCColor.primary.opacity(0.2), .clear],
                            startPoint: .top, endPoint: .bottom))
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 44)
        }
        .padding(NDCSpacing.gutter)
        .cardBorder()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pr.exercise): \(Int(pr.value)) kilos, \(pr.ago)")
    }
}

// MARK: - Borde de tarjeta estándar

private extension View {
    func cardBorder() -> some View {
        background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.large)
                    .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
            )
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct ProfileData {
    struct PRMark: Identifiable {
        let id = UUID()
        let exercise: String
        let value: Double
        let ago: String
        let history: [Double]
    }
    struct MedicalNote: Identifiable {
        let id = UUID()
        let isWarning: Bool
        let text: String
    }
    struct InjuryItem: Identifiable {
        let id = UUID()
        let name: String
        let status: String
        let severity: String
        let isModerate: Bool
    }

    let attended: Int
    let monthlyTotal: Int
    let weightDelta: String
    let goalTitle: String
    let goalProgress: Double
    let prHistory: [PRMark]
    let medicalNotes: [MedicalNote]
    let injuries: [InjuryItem]
    let unreadCount: Int

    static let sample = ProfileData(
        attended: 22,
        monthlyTotal: 24,
        weightDelta: "-0.8kg",
        goalTitle: "Ganar masa muscular y mejorar estabilidad en Clean & Jerk.",
        goalProgress: 0.85,
        prHistory: [
            PRMark(exercise: "Sentadilla Trasera", value: 145, ago: "Hace 3 días",
                   history: [120, 125, 122, 130, 135, 140, 145]),
            PRMark(exercise: "Cargada", value: 110, ago: "Hace 12 días",
                   history: [95, 98, 100, 104, 106, 110]),
            PRMark(exercise: "Arrancada", value: 85, ago: "Ayer",
                   history: [70, 74, 72, 78, 80, 85])
        ],
        medicalNotes: [
            MedicalNote(isWarning: true, text: "Molestia leve en tendón rotuliano derecho. Evitar saltos de cajón de alta intensidad."),
            MedicalNote(isWarning: false, text: "Enfoque en movilidad de hombros previo a trabajos Overhead.")
        ],
        injuries: [
            InjuryItem(name: "Sobrecarga en lumbar", status: "Reportado hace 2 días", severity: "Moderada", isModerate: true),
            InjuryItem(name: "Molestia en hombro izquierdo", status: "En seguimiento", severity: "Leve", isModerate: false)
        ],
        unreadCount: 2
    )
}

#Preview {
    AthleteProfileView(profile: .preview)
        .environment(SessionStore())
}
