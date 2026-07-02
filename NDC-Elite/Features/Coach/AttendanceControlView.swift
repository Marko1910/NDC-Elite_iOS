import SwiftUI

/// Control de Asistencia (coach) — diseño Stitch "Control de Asistencia".
/// Opera sobre las clases programadas de HOY (`class_sessions`, ver
/// ClassScheduleView): el coach elige la clase, ve el roster real y marca
/// presente/ausente persistido en `attendance`. El QR usa la MISMA sesión,
/// para que el check-in manual y el escaneado sumen juntos.
/// Se llega desde Gestión de Atletas ("Tomar Asistencia"). (ver FLOWS.md → AttendanceView)
struct AttendanceControlView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = AttendanceControlStore()
    @State private var showQR = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.error)
                    }
                    LoadStateView(state: store.state, retry: { Task { await store.load() } }) { data in
                        classPicker(data)
                        if let selected = data.selected {
                            daySummary(data, selected: selected)
                            Text("Atletas · Clase de las \(selected.formattedStartTime)")
                                .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                            if data.athletes.isEmpty {
                                ContentUnavailableView("Sin atletas", systemImage: "person.slash",
                                                       description: Text("Aún no hay atletas activos registrados."))
                            } else {
                                ForEach(data.athletes) { athlete in
                                    AttendanceToggleRow(
                                        athlete: athlete,
                                        isPresent: data.statusByAthlete[athlete.id] == .presente,
                                        isSaving: store.savingIds.contains(athlete.id),
                                        sessionLabel: selected.formattedStartTime
                                    ) {
                                        Task { await store.toggle(athlete) }
                                    }
                                }
                            }
                        } else {
                            noClassesState
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackMD) {
                            SkeletonCard(lines: 1, height: 76)
                            SkeletonCard(lines: 1, height: 90)
                            SkeletonCard(lines: 2, height: 72)
                            SkeletonCard(lines: 2, height: 72)
                        }
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
                .disabled(store.state.value?.selected == nil)
                .opacity(store.state.value?.selected == nil ? 0.5 : 1)
                .padding(.trailing, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackLG)
                .accessibilityLabel("Generar QR de asistencia")
            }
            .sheet(isPresented: $showQR) {
                // El QR codifica la MISMA sesión que el control manual.
                GenerateQRView(presetSession: store.state.value?.selected)
            }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Selector de clase (las programadas de hoy)

    private func classPicker(_ data: AttendanceControlStore.Data) -> some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: "timer")
                .font(.system(size: 22)).foregroundStyle(NDCColor.onAccent)
                .frame(width: 44, height: 44)
                .background(NDCColor.accent, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("CLASE DE HOY").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Text(Self.todayLabel).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            }
            Spacer()
            Menu {
                ForEach(data.sessions) { session in
                    Button {
                        Haptics.selection()
                        Task { await store.select(session) }
                    } label: {
                        if session.id == data.selected?.id {
                            Label(sessionLabel(session), systemImage: "checkmark")
                        } else {
                            Text(sessionLabel(session))
                        }
                    }
                }
                if !data.sessions.isEmpty { Divider() }
                Button {
                    Haptics.impact()
                    Task { await store.createNow() }
                } label: {
                    Label("Clase de ahora (\(Self.currentHourLabel))", systemImage: "plus")
                }
            } label: {
                HStack(spacing: 6) {
                    Text(data.selected?.formattedStartTime ?? "Elegir clase")
                        .font(NDCFont.headlineSM)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12))
                }
                .foregroundStyle(NDCColor.primary)
                .padding(.horizontal, NDCSpacing.gutter).padding(.vertical, 8)
                .background(NDCColor.primary.opacity(0.10), in: .capsule)
            }
            .accessibilityLabel("Clase seleccionada: \(data.selected?.formattedStartTime ?? "ninguna")")
        }
        .padding(NDCSpacing.gutter)
        .frame(maxWidth: .infinity)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func sessionLabel(_ session: ClassSession) -> String {
        if let title = session.title { return "\(session.formattedStartTime) · \(title)" }
        return session.formattedStartTime
    }

    private var noClassesState: some View {
        VStack(spacing: NDCSpacing.stackMD) {
            ContentUnavailableView(
                "No hay clases programadas hoy",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("Crea la clase de esta hora, o programa el horario completo desde Atletas → ícono de calendario.")
            )
            Button {
                Haptics.impact()
                Task { await store.createNow() }
            } label: {
                Label("Crear clase de ahora (\(Self.currentHourLabel))", systemImage: "plus.circle.fill")
                    .font(NDCFont.headlineSM).foregroundStyle(NDCColor.onAccent)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
            }
        }
        .padding(.top, NDCSpacing.stackMD)
    }

    private static var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: Date()).capitalized
    }

    private static var currentHourLabel: String {
        String(format: "%02d:00", Calendar.current.component(.hour, from: Date()))
    }

    // MARK: - Resumen de la clase

    private func daySummary(_ data: AttendanceControlStore.Data, selected: ClassSession) -> some View {
        let present = data.athletes.filter { data.statusByAthlete[$0.id] == .presente }.count
        let total = max(data.athletes.count, 1)
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RESUMEN DE LA CLASE").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(present)").font(NDCFont.statsXL).foregroundStyle(.white)
                    Text("/ \(data.athletes.count) atletas presentes").font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
                }
                Label("Capacidad: \(selected.capacity)", systemImage: "person.3.fill")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            Spacer()
            Text("\(Int(Double(present) / Double(total) * 100))%")
                .font(NDCFont.displayLG).foregroundStyle(NDCColor.accent)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(present) de \(data.athletes.count) atletas presentes")
    }
}

// MARK: - Fila de atleta con toggle

private struct AttendanceToggleRow: View {
    let athlete: Profile
    let isPresent: Bool
    let isSaving: Bool
    let sessionLabel: String
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(athlete.fullName).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("\(athlete.level.displayName) • \(sessionLabel)")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            Button {
                Haptics.selection()
                onToggle()
            } label: {
                Label(isPresent ? "Presente" : "Ausente",
                      systemImage: isPresent ? "checkmark.circle.fill" : "circle")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(isPresent ? NDCColor.onAccent : NDCColor.outline)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background((isPresent ? NDCColor.accent : NDCColor.surface), in: .capsule)
            }
            .disabled(isSaving)
            .opacity(isSaving ? 0.5 : 1)
            .accessibilityLabel("\(athlete.fullName): \(isPresent ? "presente" : "ausente")")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Store (clases de hoy + roster + asistencia reales)

@MainActor @Observable
final class AttendanceControlStore {
    struct Data {
        var sessions: [ClassSession]
        var selected: ClassSession?
        let athletes: [Profile]
        var statusByAthlete: [UUID: AttendanceStatus]
    }

    private(set) var state: LoadState<Data> = .loading
    private(set) var savingIds: Set<UUID> = []
    var errorMessage: String?

    private let repo = CoachRepository()

    /// Carga clases de hoy + roster; selecciona la clase en curso (o la
    /// indicada) y su asistencia.
    func load(selecting preferredId: UUID? = nil) async {
        state = .loading
        errorMessage = nil
        do {
            async let sessionsTask = repo.sessions(on: Date())
            async let athletesTask = repo.athletes()
            let (sessions, athletes) = try await (sessionsTask, athletesTask)
            let selected = sessions.first { $0.id == preferredId } ?? Self.currentSession(among: sessions)

            var statusByAthlete: [UUID: AttendanceStatus] = [:]
            if let selected {
                let attendance = try await repo.attendance(sessionId: selected.id)
                statusByAthlete = Dictionary(uniqueKeysWithValues: attendance.map { ($0.athleteId, $0.status) })
            }
            state = .loaded(Data(sessions: sessions, selected: selected,
                                 athletes: athletes, statusByAthlete: statusByAthlete))
        } catch {
            state = .failed("No se pudo cargar la asistencia de hoy.")
        }
    }

    func select(_ session: ClassSession) async {
        await load(selecting: session.id)
    }

    /// Crea (o reusa) la clase de la hora en punto actual y la selecciona.
    func createNow() async {
        errorMessage = nil
        do {
            let hour = Calendar.current.component(.hour, from: Date())
            let session = try await repo.findOrCreateSession(
                date: Date(),
                startTime: String(format: "%02d:00", hour)
            )
            Haptics.notify(.success)
            await load(selecting: session.id)
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo crear la clase. Inténtalo de nuevo."
        }
    }

    /// Toggle optimista: pinta el cambio al instante, lo persiste en
    /// `attendance` y **revierte** si el servidor falla.
    func toggle(_ athlete: Profile) async {
        guard case .loaded(var data) = state, let session = data.selected,
              !savingIds.contains(athlete.id) else { return }
        let previous = data.statusByAthlete[athlete.id] ?? .ausente
        let new: AttendanceStatus = previous == .presente ? .ausente : .presente

        data.statusByAthlete[athlete.id] = new
        withAnimation(.snappy) { state = .loaded(data) }

        savingIds.insert(athlete.id)
        defer { savingIds.remove(athlete.id) }
        do {
            try await repo.setAttendance(sessionId: session.id, athleteId: athlete.id, status: new)
            errorMessage = nil
        } catch {
            if case .loaded(var current) = state {
                current.statusByAthlete[athlete.id] = previous
                withAnimation(.snappy) { state = .loaded(current) }
            }
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la asistencia de \(athlete.firstName). Inténtalo de nuevo."
        }
    }

    /// La clase "en curso": la última que ya empezó; si ninguna, la primera.
    private static func currentSession(among sessions: [ClassSession]) -> ClassSession? {
        guard !sessions.isEmpty else { return nil }
        let now = Calendar.current.component(.hour, from: Date()) * 60
            + Calendar.current.component(.minute, from: Date())
        let started = sessions.filter { startMinutes(of: $0) <= now }
        return started.last ?? sessions.first
    }

    private static func startMinutes(of session: ClassSession) -> Int {
        let parts = session.startTime.split(separator: ":")
        let hours = Int(parts.first ?? "") ?? 0
        let minutes = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
        return hours * 60 + minutes
    }
}

#Preview {
    AttendanceControlView()
}
