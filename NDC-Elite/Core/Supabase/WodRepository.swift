import Foundation
import Supabase

/// Acceso a WODs del coach (`wods` + `wod_blocks` + `wod_block_exercises`).
struct WodRepository {
    private let client = SupabaseManager.client

    func fetchWods(from start: Date, to end: Date) async throws -> [Wod] {
        try await client
            .from("wods")
            .select()
            .gte("scheduled_date", value: Self.isoDate(start))
            .lte("scheduled_date", value: Self.isoDate(end))
            .order("scheduled_date")
            .execute()
            .value
    }

    func fetchBlocks(wodId: UUID) async throws -> [WodBlock] {
        try await client
            .from("wod_blocks")
            .select()
            .eq("wod_id", value: wodId)
            .order("position")
            .execute()
            .value
    }

    func fetchBlockExercises(blockIds: [UUID]) async throws -> [WodBlockExercise] {
        guard !blockIds.isEmpty else { return [] }
        return try await client
            .from("wod_block_exercises")
            .select()
            .in("block_id", values: blockIds)
            .order("position")
            .execute()
            .value
    }

    /// Crea o reemplaza el WOD completo: fila `wods`, y sus bloques/ejercicios
    /// (borra los bloques existentes y los reinserta, igual que con los pasos
    /// de técnica de ejercicios — más simple que diffear).
    @discardableResult
    func saveWod(id: UUID, title: String, scheduledDate: Date, wodType: WodType,
                 status: WodStatus, timeCapMinutes: Int?, createdBy: UUID,
                 blocks: [WodEditorBlockInput]) async throws -> UUID {
        try await client.from("wods").upsert(WodUpsertRow(
            id: id, title: title, scheduledDate: Self.isoDate(scheduledDate),
            wodType: wodType, status: status, timeCapMinutes: timeCapMinutes, createdBy: createdBy
        )).execute()

        try await client.from("wod_blocks").delete().eq("wod_id", value: id).execute()

        for (blockIndex, block) in blocks.enumerated() {
            let blockId = UUID()
            try await client.from("wod_blocks").insert(WodBlockInsertRow(
                id: blockId, wodId: id, blockType: block.type, title: block.title, position: blockIndex + 1
            )).execute()

            guard !block.exercises.isEmpty else { continue }
            let exerciseRows = block.exercises.enumerated().map { index, ex in
                WodBlockExerciseInsertRow(
                    blockId: blockId, exerciseId: ex.exerciseId, position: index + 1,
                    prescription: ex.prescription.isEmpty ? ex.exerciseName : ex.prescription
                )
            }
            try await client.from("wod_block_exercises").insert(exerciseRows).execute()
        }
        return id
    }

    func delete(wodId: UUID) async throws {
        try await client.from("wods").delete().eq("id", value: wodId).execute()
    }

    /// Publica una sesión de running (wod_type = running, sin bloques).
    /// La hora de salida viaja en `focus` (los wods no tienen columna de hora).
    func publishRunning(title: String, scheduledDate: Date, startLabel: String,
                        distanceKm: Double?, paceTarget: String?, routeURL: String?,
                        notes: String?, createdBy: UUID) async throws {
        struct Row: Encodable {
            let title: String
            let scheduledDate: String
            let wodType: WodType
            let status: WodStatus
            let focus: String
            let distanceKm: Double?
            let paceTarget: String?
            let routeURL: String?
            let isOutdoor: Bool
            let notes: String?
            let createdBy: UUID

            enum CodingKeys: String, CodingKey {
                case title, status, focus, notes
                case scheduledDate = "scheduled_date"
                case wodType = "wod_type"
                case distanceKm = "distance_km"
                case paceTarget = "pace_target"
                case routeURL = "route_url"
                case isOutdoor = "is_outdoor"
                case createdBy = "created_by"
            }
        }
        try await client.from("wods")
            .insert(Row(title: title, scheduledDate: Self.isoDate(scheduledDate),
                        wodType: .running, status: .publicado, focus: "Salida \(startLabel)",
                        distanceKm: distanceKm, paceTarget: paceTarget, routeURL: routeURL,
                        isOutdoor: true, notes: notes, createdBy: createdBy))
            .execute()
    }

    /// Formatea una Date como "yyyy-MM-dd" usando la zona horaria local.
    /// Antes usaba UTC, lo que causaba que después de ~7PM (UTC-5) las fechas
    /// se desfasaran al día siguiente.
    static func isoDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }
}

/// Bloque editable + sus ejercicios, tal como los arma el coach en el editor.
struct WodEditorBlockInput {
    let type: BlockType
    let title: String
    let exercises: [WodEditorExerciseInput]
}

struct WodEditorExerciseInput {
    let exerciseId: UUID
    let exerciseName: String
    let prescription: String
}

private struct WodUpsertRow: Encodable {
    let id: UUID
    let title: String
    let scheduledDate: String
    let wodType: WodType
    let status: WodStatus
    let timeCapMinutes: Int?
    let createdBy: UUID

    enum CodingKeys: String, CodingKey {
        case id, title, status
        case scheduledDate = "scheduled_date"
        case wodType = "wod_type"
        case timeCapMinutes = "time_cap_minutes"
        case createdBy = "created_by"
    }
}

private struct WodBlockInsertRow: Encodable {
    let id: UUID
    let wodId: UUID
    let blockType: BlockType
    let title: String
    let position: Int

    enum CodingKeys: String, CodingKey {
        case id, title, position
        case wodId = "wod_id"
        case blockType = "block_type"
    }
}

private struct WodBlockExerciseInsertRow: Encodable {
    let blockId: UUID
    let exerciseId: UUID
    let position: Int
    let prescription: String

    enum CodingKeys: String, CodingKey {
        case position, prescription
        case blockId = "block_id"
        case exerciseId = "exercise_id"
    }
}
