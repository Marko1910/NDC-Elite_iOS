import Foundation

/// Tabla `exercises` — biblioteca técnica de ejercicios.
struct Exercise: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var nameEs: String?
    var category: ExerciseCategory
    var difficulty: AthleteLevel
    var description: String?
    var videoURL: String?
    var imageURL: String?
    var defaultScoreType: ScoreType

    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty, description
        case nameEs = "name_es"
        case videoURL = "video_url"
        case imageURL = "image_url"
        case defaultScoreType = "default_score_type"
    }
}

/// Tabla `exercise_technique_steps` — pasos numerados de técnica (Setup, Descenso...).
struct ExerciseTechniqueStep: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let exerciseId: UUID
    var stepNumber: Int
    var title: String
    var description: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case exerciseId = "exercise_id"
        case stepNumber = "step_number"
    }
}
