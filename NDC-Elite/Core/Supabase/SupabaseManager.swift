import Foundation
import Supabase

/// Punto único de acceso al cliente de Supabase.
/// La clave publishable es segura en el cliente: los datos los protege RLS.
enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://rdbibgwnmrifscisicgv.supabase.co")!,
        supabaseKey: "sb_publishable_FusxC8i5Uu5fJCsxWuPb4w_XwutfrIc",
        options: SupabaseClientOptions(
            db: .init(encoder: postgresEncoder, decoder: postgresDecoder),
            auth: .init(storage: UserDefaultsLocalStorage())
        )
    )

    /// Decoder robusto para las fechas de Postgres. PostgREST devuelve
    /// timestamptz con fracción de **microsegundos** (5-6 dígitos, p.ej.
    /// `2026-06-30T19:56:49.274463+00:00`), que `ISO8601DateFormatter` no parsea
    /// (solo admite 3). Normalizamos la fracción a milisegundos antes de parsear.
    /// Maneja: timestamptz con/sin fracción y `date` plano (`yyyy-MM-dd`).
    private static let postgresDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if let date = parsePostgresDate(raw) { return date }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Formato de fecha no reconocido: \(raw)"
            )
        }
        return decoder
    }()

    /// Intenta parsear una fecha de Postgres en cualquiera de sus formatos.
    static func parsePostgresDate(_ raw: String) -> Date? {
        // Recorta la fracción de segundos a 3 dígitos (ms) si trae más.
        let normalized = normalizeFraction(raw)

        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFractional.date(from: normalized) { return date }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        if let date = iso.date(from: normalized) { return date }
        if let date = iso.date(from: raw) { return date }

        let dateOnly = DateFormatter()
        dateOnly.dateFormat = "yyyy-MM-dd"
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.timeZone = TimeZone(identifier: "UTC")
        return dateOnly.date(from: raw)
    }

    /// Deja la fracción de segundos en máximo 3 dígitos para `ISO8601DateFormatter`.
    /// `...49.274463+00:00` → `...49.274+00:00`. Sin fracción, no toca nada.
    private static func normalizeFraction(_ s: String) -> String {
        guard let dot = s.firstIndex(of: ".") else { return s }
        let after = s.index(after: dot)
        // Encuentra dónde termina la parte numérica de la fracción.
        var end = after
        while end < s.endIndex, s[end].isNumber { end = s.index(after: end) }
        let digits = s.distance(from: after, to: end)
        guard digits > 3 else { return s }
        let cut = s.index(after: s.index(dot, offsetBy: 3)) // punto + 3 dígitos
        return String(s[s.startIndex..<cut]) + String(s[end...])
    }

    /// Encoder que envía fechas como ISO8601 (compatible con timestamptz y date).
    private static let postgresEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

/// Almacenamiento de sesión basado en `UserDefaults`. El almacenamiento por
/// defecto de supabase-swift usa Keychain, que falla en builds de simulador sin
/// firma de código (la sesión no persiste y las consultas van como anónimas →
/// RLS las bloquea). Con este storage la sesión persiste de forma fiable en
/// simulador y dispositivo.
struct UserDefaultsLocalStorage: AuthLocalStorage {
    private let defaults = UserDefaults.standard
    private let prefix = "ndc.supabase.auth."

    func store(key: String, value: Data) throws {
        defaults.set(value, forKey: prefix + key)
    }
    func retrieve(key: String) throws -> Data? {
        defaults.data(forKey: prefix + key)
    }
    func remove(key: String) throws {
        defaults.removeObject(forKey: prefix + key)
    }
}
