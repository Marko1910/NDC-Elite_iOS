import Foundation

/// Tabla `class_sessions` — clase programada (única por fecha+hora).
struct ClassSession: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var sessionDate: Date
    /// Hora de inicio "07:00:00" (tipo `time` de Postgres)
    var startTime: String
    var capacity: Int
    var title: String?
    var coachId: UUID?
    var wodId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, capacity, title
        case sessionDate = "session_date"
        case startTime = "start_time"
        case coachId = "coach_id"
        case wodId = "wod_id"
    }

    /// "07:00 AM" para mostrar en UI
    var formattedStartTime: String {
        let parts = startTime.split(separator: ":")
        guard let hour = Int(parts.first ?? ""), parts.count >= 2 else { return startTime }
        let minute = String(parts[1])
        let period = hour < 12 ? "AM" : "PM"
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        return String(format: "%02d:%@ %@", hour12, minute, period)
    }
}

/// Tabla `attendance` — asistencia de un atleta a una clase (única por sesión+atleta).
struct Attendance: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let sessionId: UUID
    let athleteId: UUID
    var status: AttendanceStatus
    var checkedInAt: Date?
    /// 'qr' | 'manual'
    var checkInMethod: String?
    var recordedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id, status
        case sessionId = "session_id"
        case athleteId = "athlete_id"
        case checkedInAt = "checked_in_at"
        case checkInMethod = "check_in_method"
        case recordedBy = "recorded_by"
    }
}
