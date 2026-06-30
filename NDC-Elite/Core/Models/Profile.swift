import Foundation

/// Tabla `profiles` — perfil de usuario (atleta o coach), 1:1 con auth.users.
struct Profile: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var fullName: String
    var avatarURL: String?
    var role: UserRole
    var level: AthleteLevel
    var weightKg: Double?
    var memberSince: Date
    var monthlyAttendanceGoal: Int
    var streakDays: Int
    var points: Int
    var isActive: Bool
    var phone: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarURL = "avatar_url"
        case role, level
        case weightKg = "weight_kg"
        case memberSince = "member_since"
        case monthlyAttendanceGoal = "monthly_attendance_goal"
        case streakDays = "streak_days"
        case points
        case isActive = "is_active"
        case phone
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var firstName: String {
        fullName.components(separatedBy: " ").first ?? fullName
    }
}

#if DEBUG
extension Profile {
    /// Perfil de ejemplo para previews de SwiftUI.
    static let preview = Profile(
        id: UUID(),
        fullName: "Alex Rivera",
        avatarURL: nil,
        role: .atleta,
        level: .avanzado,
        weightKg: 82.4,
        memberSince: Date(),
        monthlyAttendanceGoal: 22,
        streakDays: 12,
        points: 2880,
        isActive: true,
        phone: "+51987654321",
        createdAt: Date(),
        updatedAt: Date()
    )
}
#endif
