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

    // MARK: - Helpers de fecha

    static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC") ?? .current
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
