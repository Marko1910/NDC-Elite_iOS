import Foundation

/// Tabla `wods` — entrenamiento del día (incluye sesiones de running).
struct Wod: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var scheduledDate: Date
    var wodType: WodType
    var status: WodStatus
    var focus: String?
    var description: String?
    var timeCapMinutes: Int?
    // Campos de running
    var distanceKm: Double?
    var paceTarget: String?
    var routeURL: String?
    var isOutdoor: Bool
    var notes: String?
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case id, title, status, focus, description, notes
        case scheduledDate = "scheduled_date"
        case wodType = "wod_type"
        case timeCapMinutes = "time_cap_minutes"
        case distanceKm = "distance_km"
        case paceTarget = "pace_target"
        case routeURL = "route_url"
        case isOutdoor = "is_outdoor"
        case createdBy = "created_by"
    }
}

/// Tabla `wod_blocks` — bloques del WOD (Calentamiento / Fuerza / Metcon...).
struct WodBlock: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let wodId: UUID
    var blockType: BlockType
    var title: String?
    var durationMinutes: Int?
    var rounds: Int?
    var scoreType: ScoreType?
    var timeCapMinutes: Int?
    var position: Int
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, title, rounds, position, notes
        case wodId = "wod_id"
        case blockType = "block_type"
        case durationMinutes = "duration_minutes"
        case scoreType = "score_type"
        case timeCapMinutes = "time_cap_minutes"
    }
}

/// Tabla `wod_block_exercises` — ejercicio prescrito dentro de un bloque.
struct WodBlockExercise: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let blockId: UUID
    var exerciseId: UUID?
    var position: Int
    /// Prescripción completa, ej: "5 Sets de 3 Reps al 75% RM. Tempo 3-2-X-1"
    var prescription: String
    /// Carga RX, ej: "135/95 lbs"
    var rxLoad: String?
    /// Carga escalada, ej: "40/25kg"
    var scaledLoad: String?
    /// Indicación del coach, ej: "Enfócate en la estabilidad del core"
    var coachCue: String?

    enum CodingKeys: String, CodingKey {
        case id, position, prescription
        case blockId = "block_id"
        case exerciseId = "exercise_id"
        case rxLoad = "rx_load"
        case scaledLoad = "scaled_load"
        case coachCue = "coach_cue"
    }
}
