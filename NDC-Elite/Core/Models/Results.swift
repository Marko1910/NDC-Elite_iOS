import Foundation

/// Tabla `wod_results` — resultado de un atleta en un WOD (único por wod+atleta).
struct WodResult: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let wodId: UUID
    let athleteId: UUID
    var rxLevel: RxLevel
    var timeSeconds: Int?
    var reps: Int?
    var rounds: Int?
    var weightUsedKg: Double?
    var intensity: AthleteLevel?
    var athleteNotes: String?
    var status: ResultStatus
    var validatedBy: UUID?
    var validatedAt: Date?
    var isPr: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, reps, rounds, status, intensity
        case wodId = "wod_id"
        case athleteId = "athlete_id"
        case rxLevel = "rx_level"
        case timeSeconds = "time_seconds"
        case weightUsedKg = "weight_used_kg"
        case athleteNotes = "athlete_notes"
        case validatedBy = "validated_by"
        case validatedAt = "validated_at"
        case isPr = "is_pr"
        case createdAt = "created_at"
    }

    /// "3:45" a partir de time_seconds
    var formattedTime: String? {
        guard let timeSeconds else { return nil }
        return String(format: "%d:%02d", timeSeconds / 60, timeSeconds % 60)
    }
}

/// Tabla `personal_records` — PRs / marcas personales con flujo de validación.
struct PersonalRecord: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    let exerciseId: UUID
    /// 145 (kg) o 225 (segundos si scoreType == .tiempo)
    var value: Double
    var scoreType: ScoreType
    var rxLevel: RxLevel
    var recordDate: Date
    var athleteNotes: String?
    /// Marca anterior, para mostrar "+5kg" y "% del PR previo"
    var previousValue: Double?
    var status: ResultStatus
    var validatedBy: UUID?
    var validatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, value, status
        case athleteId = "athlete_id"
        case exerciseId = "exercise_id"
        case scoreType = "score_type"
        case rxLevel = "rx_level"
        case recordDate = "record_date"
        case athleteNotes = "athlete_notes"
        case previousValue = "previous_value"
        case validatedBy = "validated_by"
        case validatedAt = "validated_at"
    }

    /// Mejora vs marca anterior, ej: +5.0
    var improvement: Double? {
        guard let previousValue else { return nil }
        return value - previousValue
    }
}
