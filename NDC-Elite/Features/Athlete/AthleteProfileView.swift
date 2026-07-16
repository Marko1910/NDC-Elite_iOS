import SwiftUI
import Charts

/// Tab 5 · Perfil del atleta — diseño Stitch "Perfil de Atleta - Con Registro de
/// Lesiones". ID card · bento (asistencia/peso/racha) · meta principal ·
/// historial de marcas con sparklines reales (Swift Charts) · notas médicas ·
/// registro de lesiones (+ Registrar Nueva Lesión). (ver FLOWS.md → AthleteProfileView)
struct AthleteProfileView: View {
    let profile: Profile
    @Environment(SessionStore.self) private var session
    @State private var store = AthleteProfileStore()

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
            .task { await store.load(athleteId: profile.id) }
            .refreshable { await store.load(athleteId: profile.id) }
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
            VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                Text("ASISTENCIA MENSUAL")
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(store.attended)")
                        .font(NDCFont.statsXL)
                        .foregroundStyle(NDCColor.primary)
                    Text("/ \(store.monthlyTotal)")
                        .font(NDCFont.bodyLG)
                        .foregroundStyle(NDCColor.outline)
                }
                ProgressBar(value: store.monthlyTotal > 0 ? Double(store.attended) / Double(store.monthlyTotal) : 0)
                HStack {
                    Text("Objetivo: \(profile.monthlyAttendanceGoal)")
                    Spacer()
                    if store.attended > profile.monthlyAttendanceGoal {
                        Text("+\(store.attended - profile.monthlyAttendanceGoal) sobre meta")
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
                           unit: "kg", icon: "arrow.down", note: store.weightDelta)
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
                Text("\(Int(store.goalProgress * 100))% Completado")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
            }
            Text(store.goalTitle)
                .font(NDCFont.bodyMD)
                .foregroundStyle(NDCColor.onSurfaceVariant)
            ProgressBar(value: store.goalProgress, height: 10)
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
            LoadStateView(
                state: prStore.state,
                retry: { Task { await prStore.load(athleteId: profile.id) } }
            ) { marks in
                if marks.isEmpty {
                    ContentUnavailableView(
                        "Aún sin marcas",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Registra tu primer PR para ver tu evolución aquí.")
                    )
                } else {
                    VStack(spacing: NDCSpacing.gutter) {
                        ForEach(marks) { pr in
                            PRSparklineCard(pr: pr)
                        }
                    }
                }
            } skeleton: {
                VStack(spacing: NDCSpacing.gutter) {
                    SkeletonCard(lines: 2, height: 70)
                    SkeletonCard(lines: 2, height: 70)
                }
            }
        }
    }

    private var prStore: AthletePrHistoryStore { store.prHistory }

    // MARK: - Notas médicas (coach_notes compartidas + lesiones)

    private var medicalNotes: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label("Notas Médicas y Limitaciones", systemImage: "cross.case.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            if store.sharedNotes.isEmpty && store.injuries.isEmpty {
                Text("No hay notas médicas ni lesiones registradas.")
                    .font(NDCFont.bodyMD)
                    .foregroundStyle(NDCColor.outline)
            } else {
                ForEach(store.sharedNotes) { note in
                    HStack(alignment: .top, spacing: NDCSpacing.stackSM) {
                        Image(systemName: note.category == .lesion ? "exclamationmark.triangle.fill" : "info.circle.fill")
                            .foregroundStyle(note.category == .lesion ? NDCColor.error : NDCColor.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.content)
                                .font(NDCFont.bodyMD)
                                .foregroundStyle(NDCColor.onSurfaceVariant)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(noteCategoryLabel(note.category))
                                .font(NDCFont.labelSM)
                                .foregroundStyle(NDCColor.outline)
                        }
                        Spacer(minLength: 0)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func noteCategoryLabel(_ cat: NoteCategory) -> String {
        switch cat {
        case .general: return "General"
        case .performance: return "Rendimiento"
        case .lesion: return "Lesión"
        case .nutricion: return "Nutrición"
        }
    }

    // MARK: - Lesiones

    private var injuriesSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label("Registro de Lesiones y Preocupaciones", systemImage: "bandage.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onSurface)
            if store.injuries.isEmpty {
                Text("Sin lesiones registradas. ¡Sigue así! 💪")
                    .font(NDCFont.bodyMD)
                    .foregroundStyle(NDCColor.outline)
            } else {
                ForEach(store.injuries) { injury in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bodyZoneLabel(injury.bodyZone))
                                .font(NDCFont.bodyMD)
                                .foregroundStyle(NDCColor.onSurface)
                            Text(injury.status.rawValue)
                                .font(NDCFont.labelSM)
                                .foregroundStyle(NDCColor.outline)
                        }
                        Spacer()
                        Text(injury.severity.rawValue.capitalized)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(injury.severity == .moderada || injury.severity == .severa ? NDCColor.error : NDCColor.onAccent)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background((injury.severity == .moderada || injury.severity == .severa ? NDCColor.error : NDCColor.accent).opacity(0.18),
                                        in: .capsule)
                    }
                    .padding(NDCSpacing.gutter)
                    .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.standard))
                    .accessibilityElement(children: .combine)
                }
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

    private func bodyZoneLabel(_ zone: BodyZone) -> String {
        zone.displayName
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
    let pr: PrMark

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

// MARK: - Alias para reutilizar el mismo tipo

typealias PrMark = ProfileData.PRMark

// MARK: - Store unificado del perfil (carga desde Supabase)

@MainActor @Observable
final class AthleteProfileStore {
    fileprivate(set) var prHistory = AthletePrHistoryStore()

    fileprivate(set) var attended = 0
    fileprivate(set) var monthlyTotal = 24
    fileprivate(set) var weightDelta = "-"
    fileprivate(set) var goalTitle = "Sin meta definida"
    fileprivate(set) var goalProgress: Double = 0
    fileprivate(set) var sharedNotes: [CoachNote] = []
    fileprivate(set) var injuries: [Injury] = []

    private let repo = AthleteRepository()

    func load(athleteId: UUID) async {
        async let attendedTask = repo.monthlyAttendance(athleteId: athleteId)
        async let goalTask = repo.primaryGoal(athleteId: athleteId)
        async let notesTask = repo.sharedNotes(athleteId: athleteId)
        async let injuriesTask = repo.injuries(athleteId: athleteId)

        let (attendedVal, goal, notes, injuriesVal) = await (try? attendedTask) ?? 0,
                                                              (try? goalTask) as AthleteGoal?? ?? nil,
                                                              (try? notesTask) ?? [],
                                                              (try? injuriesTask) ?? []

        attended = attendedVal
        if let g = goal {
            goalTitle = g.title
            goalProgress = g.progress
        }
        sharedNotes = notes
        injuries = injuriesVal

        await prHistory.load(athleteId: athleteId)
    }
}

// MARK: - Store (historial de PR real, agrupado por ejercicio)

@MainActor @Observable
final class AthletePrHistoryStore {
    fileprivate var state: LoadState<[PrMark]> = .loading
    private let repo = AthleteRepository()

    func load(athleteId: UUID) async {
        state = .loading
        do {
            let records = try await repo.personalRecords(athleteId: athleteId)
            guard !records.isEmpty else { state = .loaded([]); return }

            let exerciseIds = Array(Set(records.map(\.exerciseId)))
            let exercises = try await repo.exercises(ids: exerciseIds)
            let namesById = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.nameEs ?? $0.name) })

            let grouped = Dictionary(grouping: records, by: \.exerciseId)
            let entries: [(Date, PrMark)] = grouped.compactMap { exerciseId, recs in
                let sorted = recs.sorted { $0.recordDate < $1.recordDate }
                guard let latest = sorted.last else { return nil }
                let mark = PrMark(
                    exercise: namesById[exerciseId] ?? "Ejercicio",
                    value: latest.value,
                    ago: Self.relative(latest.recordDate),
                    history: sorted.suffix(6).map(\.value)
                )
                return (latest.recordDate, mark)
            }
            let ordered = entries.sorted { $0.0 > $1.0 }.map(\.1)
            state = .loaded(Array(ordered.prefix(3)))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "es")
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Extensiones de AthleteRepository para perfil

extension AthleteRepository {
    /// Notas del coach visibles para el atleta (compartidas o de lesión).
    func sharedNotes(athleteId: UUID) async throws -> [CoachNote] {
        try await client
            .from("coach_notes")
            .select()
            .eq("athlete_id", value: athleteId)
            .order("note_date", ascending: false)
            .execute()
            .value
    }

    /// Lesiones del atleta, más recientes primero.
    func injuries(athleteId: UUID) async throws -> [Injury] {
        try await client
            .from("injuries")
            .select()
            .eq("athlete_id", value: athleteId)
            .order("incident_date", ascending: false)
            .execute()
            .value
    }
}

// MARK: - Datos de muestra (mantenido para previews)

struct ProfileData {
    struct PRMark: Identifiable {
        let id = UUID()
        let exercise: String
        let value: Double
        let ago: String
        let history: [Double]
    }

    static let samplePr = PrMark(
        exercise: "SENTADILLA",
        value: 85,
        ago: "hace 3 días",
        history: [70, 72, 75, 78, 80, 85]
    )
}

#Preview {
    AthleteProfileView(profile: .preview)
        .environment(SessionStore())
}
