import Foundation
import Supabase

/// Biblioteca Técnica en Supabase (`exercises` + `exercise_technique_steps`).
/// Lectura abierta a autenticados; alta/edición/borrado solo coach (RLS).
struct ExerciseRepository {
    private let client = SupabaseManager.client

    func fetchLibrary() async throws -> [LibraryExercise] {
        let exercises: [Exercise] = try await client
            .from("exercises")
            .select()
            .order("name")
            .execute()
            .value
        guard !exercises.isEmpty else { return [] }

        let ids = exercises.map(\.id)
        let steps: [TechniqueStepRow] = try await client
            .from("exercise_technique_steps")
            .select()
            .in("exercise_id", values: ids)
            .order("step_number")
            .execute()
            .value
        let stepsByExercise = Dictionary(grouping: steps, by: \.exerciseId)

        return exercises.map { ex in
            LibraryExercise(
                id: ex.id,
                name: ex.name,
                subtitle: ex.nameEs ?? "",
                category: ex.category,
                level: ex.difficulty,
                youtubeURL: ex.videoURL ?? "",
                summary: ex.description ?? "",
                scoreType: ex.defaultScoreType,
                steps: (stepsByExercise[ex.id] ?? []).map { .init(title: $0.title, detail: $0.description ?? "") }
            )
        }
    }

    /// Crea o reemplaza un ejercicio (por `id`) y sincroniza sus pasos de
    /// técnica (borra los existentes e inserta el set actual: más simple que
    /// diffear, y el volumen por ejercicio es pequeño).
    func upsert(_ exercise: LibraryExercise, createdBy: UUID) async throws {
        try await client.from("exercises").upsert(ExerciseUpsertRow(
            id: exercise.id,
            name: exercise.name,
            nameEs: exercise.subtitle,
            category: exercise.category,
            difficulty: exercise.level,
            description: exercise.summary,
            videoURL: exercise.youtubeURL,
            defaultScoreType: exercise.scoreType,
            createdBy: createdBy
        )).execute()

        try await client.from("exercise_technique_steps")
            .delete()
            .eq("exercise_id", value: exercise.id)
            .execute()

        if !exercise.steps.isEmpty {
            let rows = exercise.steps.enumerated().map { index, step in
                TechniqueStepInsertRow(
                    exerciseId: exercise.id,
                    stepNumber: index + 1,
                    title: step.title,
                    description: step.detail
                )
            }
            try await client.from("exercise_technique_steps").insert(rows).execute()
        }
    }

    func delete(id: UUID) async throws {
        try await client.from("exercises").delete().eq("id", value: id).execute()
    }
}

private struct ExerciseUpsertRow: Encodable {
    let id: UUID
    let name: String
    let nameEs: String
    let category: ExerciseCategory
    let difficulty: AthleteLevel
    let description: String
    let videoURL: String
    let defaultScoreType: ScoreType
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case id, name, category, difficulty, description
        case nameEs = "name_es"
        case videoURL = "video_url"
        case defaultScoreType = "default_score_type"
        case createdBy = "created_by"
    }
}

private struct TechniqueStepInsertRow: Encodable {
    let exerciseId: UUID
    let stepNumber: Int
    let title: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case title, description
        case exerciseId = "exercise_id"
        case stepNumber = "step_number"
    }
}

private struct TechniqueStepRow: Decodable {
    let exerciseId: UUID
    let stepNumber: Int
    let title: String
    let description: String?

    enum CodingKeys: String, CodingKey {
        case title, description
        case exerciseId = "exercise_id"
        case stepNumber = "step_number"
    }
}
