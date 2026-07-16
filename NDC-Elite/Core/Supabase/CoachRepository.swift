import Foundation
import Supabase

/// Acceso a datos agregados del coach en Supabase (vista del gimnasio completo).
/// RLS permite al coach ver `attendance`/`profiles` de todos los atletas.
struct CoachRepository {
    private let client = SupabaseManager.client

    // MARK: - Rendimiento Semanal (Dashboard del coach)

    /// Asistencias "presente" por día, de lunes a domingo, de la semana que
    /// contiene `reference`. Clave = inicio de día (medianoche local).
    func weeklyAttendanceCounts(containing reference: Date) async throws -> [Date: Int] {
        let calendar = Self.calendar
        let start = Self.startOfWeek(containing: reference)
        let end = calendar.date(byAdding: .day, value: 7, to: start)!

        let rows: [Attendance] = try await client
            .from("attendance")
            .select()
            .eq("status", value: AttendanceStatus.presente.rawValue)
            .gte("checked_in_at", value: start.ISO8601Format())
            .lt("checked_in_at", value: end.ISO8601Format())
            .execute()
            .value

        var counts: [Date: Int] = [:]
        for row in rows {
            guard let checkedIn = row.checkedInAt else { continue }
            let day = calendar.startOfDay(for: checkedIn)
            counts[day, default: 0] += 1
        }
        return counts
    }

    /// Asistencias "presente" de hoy (para el card del dashboard).
    func presentCountToday() async throws -> Int {
        let start = Self.calendar.startOfDay(for: Date())
        let end = Self.calendar.date(byAdding: .day, value: 1, to: start)!
        let rows: [Attendance] = try await client
            .from("attendance")
            .select()
            .eq("status", value: AttendanceStatus.presente.rawValue)
            .gte("checked_in_at", value: start.ISO8601Format())
            .lt("checked_in_at", value: end.ISO8601Format())
            .execute()
            .value
        return rows.count
    }

    /// Asistencias "presente" de los últimos `days` días (para calcular
    /// cuántos días lleva ausente cada atleta).
    func recentPresence(days: Int = 30) async throws -> [Attendance] {
        let start = Self.calendar.date(byAdding: .day, value: -days,
                                       to: Self.calendar.startOfDay(for: Date()))!
        return try await client
            .from("attendance")
            .select()
            .eq("status", value: AttendanceStatus.presente.rawValue)
            .gte("checked_in_at", value: start.ISO8601Format())
            .execute()
            .value
    }

    // MARK: - Tasa de Adherencia (Progreso Comunitario)

    /// % de atletas activos que asistieron cada día, en los últimos `days` días
    /// (incluyendo hoy).
    func adherenceByDay(days: Int = 7) async throws -> [(date: Date, percent: Int)] {
        struct AthleteIdRow: Decodable { let id: UUID }
        let athletes: [AthleteIdRow] = try await client
            .from("profiles")
            .select("id")
            .eq("role", value: UserRole.atleta.rawValue)
            .eq("is_active", value: true)
            .execute()
            .value
        let totalAthletes = athletes.count
        guard totalAthletes > 0 else { return [] }

        let calendar = Self.calendar
        let todayStart = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: todayStart)!

        let rows: [Attendance] = try await client
            .from("attendance")
            .select()
            .eq("status", value: AttendanceStatus.presente.rawValue)
            .gte("checked_in_at", value: start.ISO8601Format())
            .lt("checked_in_at", value: end.ISO8601Format())
            .execute()
            .value

        var athletesByDay: [Date: Set<UUID>] = [:]
        for row in rows {
            guard let checkedIn = row.checkedInAt else { continue }
            let day = calendar.startOfDay(for: checkedIn)
            athletesByDay[day, default: []].insert(row.athleteId)
        }

        return (0..<days).map { offset in
            let day = calendar.date(byAdding: .day, value: -(days - 1 - offset), to: todayStart)!
            let attended = athletesByDay[day]?.count ?? 0
            let percent = Int((Double(attended) / Double(totalAthletes) * 100).rounded())
            return (day, percent)
        }
    }

    // MARK: - Atletas (gestión)

    /// Atletas activos del box, ordenados por nombre.
    func athletes() async throws -> [Profile] {
        try await client
            .from("profiles")
            .select()
            .eq("role", value: UserRole.atleta.rawValue)
            .eq("is_active", value: true)
            .order("full_name", ascending: true)
            .execute()
            .value
    }

    /// Ids de atletas con lesiones sin resolver (para el filtro "Con Lesión").
    func athletesWithActiveInjury() async throws -> Set<UUID> {
        struct Row: Decodable {
            let athleteId: UUID
            enum CodingKeys: String, CodingKey { case athleteId = "athlete_id" }
        }
        let rows: [Row] = try await client
            .from("injuries")
            .select("athlete_id")
            .neq("status", value: InjuryStatus.resuelta.rawValue)
            .execute()
            .value
        return Set(rows.map(\.athleteId))
    }

    // MARK: - Notas del coach

    /// Nota sobre un atleta (RLS exige coach_id = usuario autenticado).
    func addNote(athleteId: UUID, category: NoteCategory, content: String,
                 visibility: NoteVisibility, noteDate: Date) async throws {
        let coachId = try currentCoachId()
        struct Row: Encodable {
            let athleteId: UUID
            let coachId: UUID
            let category: NoteCategory
            let content: String
            let visibility: NoteVisibility
            let noteDate: String

            enum CodingKeys: String, CodingKey {
                case category, content, visibility
                case athleteId = "athlete_id"
                case coachId = "coach_id"
                case noteDate = "note_date"
            }
        }
        try await client.from("coach_notes")
            .insert(Row(athleteId: athleteId, coachId: coachId, category: category,
                        content: content, visibility: visibility,
                        noteDate: WodRepository.isoDate(noteDate)))
            .execute()
    }

    // MARK: - Validación de marcas

    /// Resultados de WOD en estado pendiente (más recientes primero).
    func pendingWodResults() async throws -> [WodResult] {
        try await client
            .from("wod_results")
            .select()
            .eq("status", value: ResultStatus.pendiente.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Todas las marcas del box, más recientes primero (RLS: coach ve todas).
    /// ponytail: límite fijo; paginación cuando el historial crezca.
    func allPersonalRecords(limit: Int = 200) async throws -> [PersonalRecord] {
        try await client
            .from("personal_records")
            .select()
            .order("record_date", ascending: false)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// PRs en estado pendiente (más recientes primero).
    func pendingPersonalRecords() async throws -> [PersonalRecord] {
        try await client
            .from("personal_records")
            .select()
            .eq("status", value: ResultStatus.pendiente.rawValue)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// Perfiles por id (nombres/avatares de los atletas de la cola).
    func profiles(ids: [UUID]) async throws -> [Profile] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("profiles")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    /// WODs por id (título del WOD de cada resultado pendiente).
    func wods(ids: [UUID]) async throws -> [Wod] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("wods")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    /// Campos comunes de validación/corrección.
    private struct ValidationPatch: Encodable {
        let status: ResultStatus
        let validatedBy: UUID
        let validatedAt: Date

        enum CodingKeys: String, CodingKey {
            case status
            case validatedBy = "validated_by"
            case validatedAt = "validated_at"
        }
    }

    /// Valida en lote. Solo toca filas que **sigan pendientes** (si otro proceso
    /// las validó/corrigió entre la carga y el tap, no las pisa).
    func validate(wodResultIds: [UUID] = [], personalRecordIds: [UUID] = []) async throws {
        let patch = ValidationPatch(status: .validado, validatedBy: try currentCoachId(), validatedAt: Date())
        if !wodResultIds.isEmpty {
            try await client.from("wod_results").update(patch)
                .in("id", values: wodResultIds)
                .eq("status", value: ResultStatus.pendiente.rawValue)
                .execute()
        }
        if !personalRecordIds.isEmpty {
            try await client.from("personal_records").update(patch)
                .in("id", values: personalRecordIds)
                .eq("status", value: ResultStatus.pendiente.rawValue)
                .execute()
        }
    }

    /// Corrige un resultado de WOD: solo sobreescribe las métricas provistas
    /// (las nil no viajan) y lo marca corregido + validado por el coach.
    func correctWodResult(id: UUID, timeSeconds: Int?, reps: Int?, rounds: Int?,
                          weightUsedKg: Double?) async throws {
        struct Patch: Encodable {
            let timeSeconds: Int?
            let reps: Int?
            let rounds: Int?
            let weightUsedKg: Double?
            let status: ResultStatus
            let validatedBy: UUID
            let validatedAt: Date

            enum CodingKeys: String, CodingKey {
                case reps, rounds, status
                case timeSeconds = "time_seconds"
                case weightUsedKg = "weight_used_kg"
                case validatedBy = "validated_by"
                case validatedAt = "validated_at"
            }
        }
        try await client.from("wod_results")
            .update(Patch(timeSeconds: timeSeconds, reps: reps, rounds: rounds,
                          weightUsedKg: weightUsedKg, status: .corregido,
                          validatedBy: try currentCoachId(), validatedAt: Date()))
            .eq("id", value: id)
            .execute()
    }

    /// Corrige el valor de un PR y lo marca corregido + validado por el coach.
    func correctPersonalRecord(id: UUID, value: Double) async throws {
        struct Patch: Encodable {
            let value: Double
            let status: ResultStatus
            let validatedBy: UUID
            let validatedAt: Date

            enum CodingKeys: String, CodingKey {
                case value, status
                case validatedBy = "validated_by"
                case validatedAt = "validated_at"
            }
        }
        try await client.from("personal_records")
            .update(Patch(value: value, status: .corregido,
                          validatedBy: try currentCoachId(), validatedAt: Date()))
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Asistencia manual (Control de Asistencia)

    /// Asistencia registrada de una sesión (para pintar los toggles).
    func attendance(sessionId: UUID) async throws -> [Attendance] {
        try await client
            .from("attendance")
            .select()
            .eq("session_id", value: sessionId)
            .execute()
            .value
    }

    /// Marca presente/ausente a un atleta en una sesión (upsert único por
    /// sesión+atleta). Al marcar ausente, `checked_in_at` se anula explícito
    /// (el encoder omitiría el nil y quedaría el timestamp viejo).
    func setAttendance(sessionId: UUID, athleteId: UUID, status: AttendanceStatus) async throws {
        struct Row: Encodable {
            let sessionId: UUID
            let athleteId: UUID
            let status: AttendanceStatus
            let checkedInAt: Date?
            let checkInMethod: String
            let recordedBy: UUID

            enum CodingKeys: String, CodingKey {
                case status
                case sessionId = "session_id"
                case athleteId = "athlete_id"
                case checkedInAt = "checked_in_at"
                case checkInMethod = "check_in_method"
                case recordedBy = "recorded_by"
            }

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(sessionId, forKey: .sessionId)
                try c.encode(athleteId, forKey: .athleteId)
                try c.encode(status, forKey: .status)
                try c.encode(checkedInAt, forKey: .checkedInAt) // null explícito
                try c.encode(checkInMethod, forKey: .checkInMethod)
                try c.encode(recordedBy, forKey: .recordedBy)
            }
        }
        try await client.from("attendance")
            .upsert(Row(sessionId: sessionId, athleteId: athleteId, status: status,
                        checkedInAt: status == .presente ? Date() : nil,
                        checkInMethod: "manual", recordedBy: try currentCoachId()),
                    onConflict: "session_id,athlete_id")
            .execute()
    }

    /// RLS exige que las escrituras del coach viajen con su id de sesión.
    private func currentCoachId() throws -> UUID {
        guard let id = client.auth.currentSession?.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        return id
    }

    // MARK: - Clases (QR de asistencia)

    /// Sesión de clase de la fecha+hora dadas; la crea si no existe (única por
    /// fecha+hora). El QR del coach codifica el id de esta sesión.
    func findOrCreateSession(date: Date, startTime: String) async throws -> ClassSession {
        try await scheduleSession(date: date, startTime: startTime, title: nil, capacity: nil)
    }

    /// Clases programadas de un día, ordenadas por hora.
    func sessions(on date: Date) async throws -> [ClassSession] {
        try await client
            .from("class_sessions")
            .select()
            .eq("session_date", value: WodRepository.isoDate(date))
            .order("start_time", ascending: true)
            .execute()
            .value
    }

    /// Crea (o actualiza título/capacidad de) una clase del horario.
    /// Única por fecha+hora; el coach que la guarda queda como coach_id.
    func scheduleSession(date: Date, startTime: String, title: String?, capacity: Int?) async throws -> ClassSession {
        struct Row: Encodable {
            let sessionDate: String
            let startTime: String
            let coachId: UUID?
            let title: String?
            let capacity: Int?

            enum CodingKeys: String, CodingKey {
                case title, capacity
                case sessionDate = "session_date"
                case startTime = "start_time"
                case coachId = "coach_id"
            }
        }
        return try await client.from("class_sessions")
            .upsert(Row(sessionDate: WodRepository.isoDate(date), startTime: startTime,
                        coachId: client.auth.currentSession?.user.id,
                        title: title, capacity: capacity),
                    onConflict: "session_date,start_time")
            .select()
            .single()
            .execute()
            .value
    }

    /// Elimina una clase del horario. OJO: borra en cascada la asistencia
    /// registrada de esa clase (FK on delete cascade) — confirmar antes en UI.
    func deleteSession(id: UUID) async throws {
        try await client.from("class_sessions").delete().eq("id", value: id).execute()
    }

    // MARK: - Helpers de fecha

    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    /// Lunes de la semana que contiene `date` (semana ISO, lunes primer día).
    static func startOfWeek(containing date: Date) -> Date {
        let day = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day) // 1 = domingo … 7 = sábado
        let daysSinceMonday = (weekday + 5) % 7 // domingo→6, lunes→0, martes→1…
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: day)!
    }
}
