import Foundation
import Supabase

/// Retos de comunidad (`challenges` + `challenge_participants`).
/// El coach crea/elimina retos (RLS: is_coach()); el atleta se une o abandona
/// su propia inscripción; todos los autenticados leen.
struct ChallengeRepository {
    private let client = SupabaseManager.client

    func activeChallenges() async throws -> [Challenge] {
        try await client
            .from("challenges")
            .select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func participants(challengeIds: [UUID]) async throws -> [ChallengeParticipant] {
        guard !challengeIds.isEmpty else { return [] }
        return try await client
            .from("challenge_participants")
            .select()
            .in("challenge_id", values: challengeIds)
            .order("joined_at")
            .execute()
            .value
    }

    /// Nombre y foto de los atletas inscritos (para mostrárselos al coach).
    func profiles(ids: [UUID]) async throws -> [Profile] {
        guard !ids.isEmpty else { return [] }
        return try await client
            .from("profiles")
            .select()
            .in("id", values: ids)
            .execute()
            .value
    }

    func join(challengeId: UUID, athleteId: UUID) async throws {
        struct Row: Encodable {
            let challengeId: UUID
            let athleteId: UUID
            enum CodingKeys: String, CodingKey {
                case challengeId = "challenge_id"
                case athleteId = "athlete_id"
            }
        }
        try await client
            .from("challenge_participants")
            .insert(Row(challengeId: challengeId, athleteId: athleteId))
            .execute()
    }

    func leave(challengeId: UUID, athleteId: UUID) async throws {
        try await client
            .from("challenge_participants")
            .delete()
            .eq("challenge_id", value: challengeId)
            .eq("athlete_id", value: athleteId)
            .execute()
    }

    func create(title: String, description: String?, type: ChallengeType,
                goalValue: Double, unit: String, endsOn: Date?, createdBy: UUID) async throws {
        struct Row: Encodable {
            let title: String
            let description: String?
            let challengeType: ChallengeType
            let goalValue: Double
            let unit: String
            let endsOn: String?
            let createdBy: UUID
            enum CodingKeys: String, CodingKey {
                case title, description, unit
                case challengeType = "challenge_type"
                case goalValue = "goal_value"
                case endsOn = "ends_on"
                case createdBy = "created_by"
            }
        }
        try await client
            .from("challenges")
            .insert(Row(title: title, description: description, challengeType: type,
                        goalValue: goalValue, unit: unit,
                        endsOn: endsOn.map(WodRepository.isoDate), createdBy: createdBy))
            .execute()
    }

    /// Cambia (o quita, con nil) la fecha límite de un reto.
    func updateEndsOn(challengeId: UUID, endsOn: Date?) async throws {
        struct Row: Encodable {
            let endsOn: String?
            enum CodingKeys: String, CodingKey { case endsOn = "ends_on" }
        }
        try await client
            .from("challenges")
            .update(Row(endsOn: endsOn.map(WodRepository.isoDate)))
            .eq("id", value: challengeId)
            .execute()
    }

    func delete(challengeId: UUID) async throws {
        try await client
            .from("challenges")
            .delete()
            .eq("id", value: challengeId)
            .execute()
    }
}
