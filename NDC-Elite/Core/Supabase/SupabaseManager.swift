import Foundation
import Supabase

/// Punto único de acceso al cliente de Supabase.
/// La clave publishable es segura en el cliente: los datos los protege RLS.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://rdbibgwnmrifscisicgv.supabase.co")!,
        supabaseKey: "sb_publishable_FusxC8i5Uu5fJCsxWuPb4w_XwutfrIc",
        options: SupabaseClientOptions(
            db: .init(encoder: postgresEncoder, decoder: postgresDecoder)
        )
    )

    /// Decoder que entiende los 3 formatos de fecha que devuelve Postgres:
    /// timestamptz con fracciones, timestamptz sin fracciones y date plano.
    private static let postgresDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            let isoFractional = ISO8601DateFormatter()
            isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFractional.date(from: string) { return date }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) { return date }

            let dateOnly = DateFormatter()
            dateOnly.dateFormat = "yyyy-MM-dd"
            dateOnly.locale = Locale(identifier: "en_US_POSIX")
            dateOnly.timeZone = TimeZone(identifier: "UTC")
            if let date = dateOnly.date(from: string) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Formato de fecha no reconocido: \(string)"
            )
        }
        return decoder
    }()

    /// Encoder que envía fechas como ISO8601 (compatible con timestamptz y date).
    private static let postgresEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
