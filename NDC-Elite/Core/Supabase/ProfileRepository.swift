import Foundation
import Supabase

/// Edición del propio perfil (nombre, foto). Cualquier usuario autenticado
/// puede editar su propia fila de `profiles` (RLS: id = auth.uid()).
struct ProfileRepository {
    private let client = SupabaseManager.client

    func updateFullName(userId: UUID, name: String) async throws {
        try await client
            .from("profiles")
            .update(["full_name": name])
            .eq("id", value: userId)
            .execute()
    }

    /// Sube la foto al bucket público `avatars` (ruta `{userId}/avatar.jpg`,
    /// se sobrescribe con `upsert`), guarda la URL pública en `profiles.avatar_url`
    /// y la devuelve.
    @discardableResult
    func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        let path = "\(userId.uuidString)/avatar.jpg"
        try await client.storage.from("avatars").upload(
            path, data: imageData,
            options: FileOptions(contentType: "image/jpeg", upsert: true)
        )
        // Cache-buster: sin esto, AsyncImage podría seguir mostrando la foto
        // anterior por la misma URL cacheada.
        let publicURL = try client.storage.from("avatars").getPublicURL(path: path)
        var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "v", value: "\(Int(Date().timeIntervalSince1970))")]
        let finalURL = components?.url ?? publicURL

        try await client
            .from("profiles")
            .update(["avatar_url": finalURL.absoluteString])
            .eq("id", value: userId)
            .execute()

        return finalURL.absoluteString
    }
}
