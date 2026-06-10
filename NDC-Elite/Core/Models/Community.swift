import Foundation

/// Tabla `challenges` — retos de comunidad e individuales.
struct Challenge: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var description: String?
    var challengeType: ChallengeType
    var goalValue: Double
    /// 'burpees', 'kg', 'km', 'reps'
    var unit: String
    var currentValue: Double
    var startsOn: Date?
    var endsOn: Date?
    var isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description, unit
        case challengeType = "challenge_type"
        case goalValue = "goal_value"
        case currentValue = "current_value"
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case isActive = "is_active"
    }

    /// Progreso colectivo 0...1 para barras de progreso
    var progress: Double {
        guard goalValue > 0 else { return 0 }
        return min(currentValue / goalValue, 1)
    }
}

/// Tabla `challenge_participants` — inscripción y progreso personal en un reto.
struct ChallengeParticipant: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let challengeId: UUID
    let athleteId: UUID
    var progressValue: Double
    let joinedAt: Date
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case challengeId = "challenge_id"
        case athleteId = "athlete_id"
        case progressValue = "progress_value"
        case joinedAt = "joined_at"
        case completedAt = "completed_at"
    }
}

/// Tabla `achievements` — catálogo de insignias (Early Bird, PR Crusher...).
struct Achievement: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var code: String
    var title: String
    var description: String?
    var icon: String?
}

/// Tabla `athlete_achievements` — insignias desbloqueadas por atleta.
struct AthleteAchievement: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    let achievementId: UUID
    let unlockedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case athleteId = "athlete_id"
        case achievementId = "achievement_id"
        case unlockedAt = "unlocked_at"
    }
}

/// Tabla `athlete_goals` — objetivos del atleta (Meta Principal, Próximo Objetivo).
struct AthleteGoal: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    var title: String
    var description: String?
    var targetValue: Double?
    var currentValue: Double
    var unit: String?
    var isPrimary: Bool
    var targetDate: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, unit
        case athleteId = "athlete_id"
        case targetValue = "target_value"
        case currentValue = "current_value"
        case isPrimary = "is_primary"
        case targetDate = "target_date"
    }

    /// Progreso 0...1 ("Actual: 8 / Meta: 10" → 0.8)
    var progress: Double {
        guard let targetValue, targetValue > 0 else { return 0 }
        return min(currentValue / targetValue, 1)
    }
}

/// Tabla `ranking_snapshots` — foto del ranking para calcular Δ posiciones (+3/−1).
struct RankingSnapshot: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let athleteId: UUID
    var points: Int
    var rank: Int
    var snapshotDate: Date

    enum CodingKeys: String, CodingKey {
        case id, points, rank
        case athleteId = "athlete_id"
        case snapshotDate = "snapshot_date"
    }
}
