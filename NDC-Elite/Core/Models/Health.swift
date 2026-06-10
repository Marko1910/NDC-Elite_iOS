import Foundation

/// Tabla `injuries` — registro de lesiones del atleta.
struct Injury: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    var bodyZone: BodyZone
    var severity: InjurySeverity
    var description: String?
    var incidentDate: Date
    var status: InjuryStatus
    var reportedBy: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, severity, description, status
        case athleteId = "athlete_id"
        case bodyZone = "body_zone"
        case incidentDate = "incident_date"
        case reportedBy = "reported_by"
        case createdAt = "created_at"
    }
}

/// Tabla `coach_notes` — notas del coach sobre un atleta.
struct CoachNote: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    let coachId: UUID
    var category: NoteCategory
    var content: String
    var visibility: NoteVisibility
    var noteDate: Date
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, category, content, visibility
        case athleteId = "athlete_id"
        case coachId = "coach_id"
        case noteDate = "note_date"
        case createdAt = "created_at"
    }
}
