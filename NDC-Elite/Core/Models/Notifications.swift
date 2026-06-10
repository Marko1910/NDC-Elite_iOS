import Foundation

/// Tabla `notifications` — alertas y notificaciones internas.
/// (Se llama AppNotification para no chocar con Foundation.Notification.)
struct AppNotification: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    let userId: UUID
    var type: NotificationType
    var title: String
    var body: String?
    var relatedAthleteId: UUID?
    var isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, type, title, body
        case userId = "user_id"
        case relatedAthleteId = "related_athlete_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

/// Tabla `coach_tips` — tips del coach ("Mejora tu eficiencia en el Clean").
struct CoachTip: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var title: String
    var content: String?
    var videoURL: String?
    var exerciseId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content
        case videoURL = "video_url"
        case exerciseId = "exercise_id"
        case createdAt = "created_at"
    }
}
