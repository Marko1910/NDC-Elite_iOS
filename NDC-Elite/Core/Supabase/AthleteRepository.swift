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

    // MARK: - Helpers

    private static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }
}
