import Foundation
import Supabase

/// Acceso a datos del atleta en Supabase. Cada método hace una consulta acotada
/// por RLS (el atleta solo ve lo suyo / contenido publicado). Devuelve modelos
/// `Codable` ya definidos en Core/Models. Las vistas usan estos métodos a través
/// de sus stores (@Observable) que exponen `LoadState`.
struct AthleteRepository {
    private let client = SupabaseManager.client

    // MARK: - Dashboard

    /// Próximo WOD publicado (hoy o el más cercano hacia adelante).
    func nextWod() async throws -> Wod? {
        let today = Self.isoDate(Date())
        let rows: [Wod] = try await client
            .from("wods")
            .select()
            .eq("status", value: WodStatus.publicado.rawValue)
            .gte("scheduled_date", value: today)
            .order("scheduled_date", ascending: true)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Bloques + ejercicios de un WOD (para el detalle).
    func blocks(for wodId: UUID) async throws -> [WodBlock] {
        try await client
            .from("wod_blocks")
            .select()
            .eq("wod_id", value: wodId)
            .order("position", ascending: true)
            .execute()
            .value
    }

    func blockExercises(for blockId: UUID) async throws -> [WodBlockExercise] {
        try await client
            .from("wod_block_exercises")
            .select()
            .eq("block_id", value: blockId)
            .order("position", ascending: true)
            .execute()
            .value
    }

    /// Conteo de PRs del atleta en los últimos 30 días.
    func recentPrCount(athleteId: UUID) async throws -> Int {
        let since = Self.isoDate(Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
        let rows: [PersonalRecord] = try await client
            .from("personal_records")
            .select()
            .eq("athlete_id", value: athleteId)
            .gte("record_date", value: since)
            .execute()
            .value
        return rows.count
    }

    /// Asistencias del atleta en el mes en curso.
    func monthlyAttendance(athleteId: UUID) async throws -> Int {
        let startOfMonth = Calendar.current.date(
            from: Calendar.current.dateComponents([.year, .month], from: Date()))!
        let rows: [Attendance] = try await client
            .from("attendance")
            .select()
            .eq("athlete_id", value: athleteId)
            .eq("status", value: AttendanceStatus.presente.rawValue)
            .gte("checked_in_at", value: startOfMonth.ISO8601Format())
            .execute()
            .value
        return rows.count
    }

    /// Objetivo principal del atleta (athlete_goals.is_primary).
    func primaryGoal(athleteId: UUID) async throws -> AthleteGoal? {
        let rows: [AthleteGoal] = try await client
            .from("athlete_goals")
            .select()
            .eq("athlete_id", value: athleteId)
            .eq("is_primary", value: true)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// Último tip del coach.
    func latestTip() async throws -> CoachTip? {
        let rows: [CoachTip] = try await client
            .from("coach_tips")
            .select()
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
        return rows.first
    }

    /// WODs pasados publicados (históricos, el más reciente primero).
    func pastWods(until today: Date = Date(), limit: Int = 60) async throws -> [Wod] {
        try await client
            .from("wods")
            .select()
            .lte("scheduled_date", value: Self.isoDate(today))
            .eq("status", value: WodStatus.publicado.rawValue)
            .order("scheduled_date", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Resultados del atleta (para cruzar con los WODs del historial).
    func wodResults(athleteId: UUID) async throws -> [WodResult] {
        try await client
            .from("wod_results")
            .select()
            .eq("athlete_id", value: athleteId)
            .execute()
            .value
    }

    /// Notificaciones del usuario, la más reciente primero (bandeja de la campana).
    func notifications(userId: UUID) async throws -> [AppNotification] {
        try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    /// Marca todas las notificaciones del usuario como leídas (al abrir la bandeja).
    func markNotificationsRead(userId: UUID) async throws {
        try await client
            .from("notifications")
            .update(["is_read": true])
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
    }

    /// Notificaciones sin leer del atleta (para el badge de la campana).
    func unreadNotifications(userId: UUID) async throws -> Int {
        let rows: [AppNotification] = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId)
            .eq("is_read", value: false)
            .execute()
            .value
        return rows.count
    }

    // MARK: - Marcas Personales (sparklines / evolución de PR)

    /// Todas las marcas del atleta, de más antigua a más reciente (para agrupar
    /// por ejercicio y graficar su evolución).
    func personalRecords(athleteId: UUID) async throws -> [PersonalRecord] {
        try await client
            .from("personal_records")
            .select()
            .eq("athlete_id", value: athleteId)
            .order("record_date", ascending: true)
            .execute()
            .value
    }

    /// Ejercicios por id (para mostrar su nombre junto a la marca).
    func exercises(ids: [UUID]) async throws -> [Exercise] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("exercises")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    /// Biblioteca completa (para el picker de "Registrar Nueva Marca").
    func allExercises() async throws -> [Exercise] {
        try await client
            .from("exercises")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
    }

    // MARK: - Registros del atleta (inserts)

    /// Resultado del WOD del día (status = pendiente, lo pone la BD). Si el
    /// atleta ya había registrado uno para ese WOD, lo reemplaza (único por
    /// wod+atleta; RLS solo permite reemplazar mientras siga pendiente).
    /// El nivel del grupo (Principiante/Intermedio/Avanzado) viaja en
    /// `intensity`; `rx_level` queda en su default de BD (el grupo no usa RX).
    func logWodResult(wodId: UUID, timeSeconds: Int?, weightUsedKg: Double?,
                      intensity: AthleteLevel?, notes: String?) async throws {
        struct Row: Encodable {
            let wodId: UUID
            let athleteId: UUID
            let timeSeconds: Int?
            let weightUsedKg: Double?
            let intensity: AthleteLevel?
            let athleteNotes: String?

            enum CodingKeys: String, CodingKey {
                case intensity
                case wodId = "wod_id"
                case athleteId = "athlete_id"
                case timeSeconds = "time_seconds"
                case weightUsedKg = "weight_used_kg"
                case athleteNotes = "athlete_notes"
            }
        }
        try await client.from("wod_results")
            .upsert(Row(wodId: wodId, athleteId: try currentUserId(),
                        timeSeconds: timeSeconds, weightUsedKg: weightUsedKg,
                        intensity: intensity, athleteNotes: notes),
                    onConflict: "wod_id,athlete_id")
            .execute()
    }

    /// Nueva marca personal (status = pendiente). Busca la marca previa del
    /// mismo ejercicio para poblar `previous_value` ("+5kg", "% del PR previo").
    func logPersonalRecord(exerciseId: UUID, value: Double, scoreType: ScoreType,
                           recordDate: Date, notes: String?) async throws {
        let athleteId = try currentUserId()
        let previous: [PersonalRecord] = try await client
            .from("personal_records")
            .select()
            .eq("athlete_id", value: athleteId)
            .eq("exercise_id", value: exerciseId)
            .order("record_date", ascending: false)
            .limit(1)
            .execute()
            .value

        struct Row: Encodable {
            let athleteId: UUID
            let exerciseId: UUID
            let value: Double
            let scoreType: ScoreType
            let recordDate: String
            let athleteNotes: String?
            let previousValue: Double?

            enum CodingKeys: String, CodingKey {
                case value
                case athleteId = "athlete_id"
                case exerciseId = "exercise_id"
                case scoreType = "score_type"
                case recordDate = "record_date"
                case athleteNotes = "athlete_notes"
                case previousValue = "previous_value"
            }
        }
        try await client.from("personal_records")
            .insert(Row(athleteId: athleteId, exerciseId: exerciseId, value: value,
                        scoreType: scoreType, recordDate: Self.isoDate(recordDate),
                        athleteNotes: notes, previousValue: previous.first?.value))
            .execute()
    }

    /// Lesión reportada por el propio atleta (status = activa, lo pone la BD).
    func logInjury(bodyZone: BodyZone, severity: InjurySeverity,
                   description: String?, incidentDate: Date) async throws {
        let athleteId = try currentUserId()
        struct Row: Encodable {
            let athleteId: UUID
            let bodyZone: BodyZone
            let severity: InjurySeverity
            let description: String?
            let incidentDate: String
            let reportedBy: UUID

            enum CodingKeys: String, CodingKey {
                case severity, description
                case athleteId = "athlete_id"
                case bodyZone = "body_zone"
                case incidentDate = "incident_date"
                case reportedBy = "reported_by"
            }
        }
        try await client.from("injuries")
            .insert(Row(athleteId: athleteId, bodyZone: bodyZone, severity: severity,
                        description: description, incidentDate: Self.isoDate(incidentDate),
                        reportedBy: athleteId))
            .execute()
    }

    /// Check-in de asistencia al escanear el QR de la clase. Lanza error de
    /// duplicado (ver `isDuplicate`) si ya hizo check-in en esa sesión.
    func checkIn(sessionId: UUID) async throws {
        let athleteId = try currentUserId()
        struct Row: Encodable {
            let sessionId: UUID
            let athleteId: UUID
            let status: AttendanceStatus
            let checkedInAt: Date
            let checkInMethod: String

            enum CodingKeys: String, CodingKey {
                case status
                case sessionId = "session_id"
                case athleteId = "athlete_id"
                case checkedInAt = "checked_in_at"
                case checkInMethod = "check_in_method"
            }
        }
        try await client.from("attendance")
            .insert(Row(sessionId: sessionId, athleteId: athleteId, status: .presente,
                        checkedInAt: Date(), checkInMethod: "qr"))
            .execute()
    }

    /// true si el error es "fila duplicada" (unique violation de Postgres).
    static func isDuplicate(_ error: Error) -> Bool {
        (error as? PostgrestError)?.code == "23505"
    }

    /// RLS exige que los registros sean del usuario autenticado.
    private func currentUserId() throws -> UUID {
        guard let id = client.auth.currentSession?.user.id else {
            throw URLError(.userAuthenticationRequired)
        }
        return id
    }

    // MARK: - Helpers

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
