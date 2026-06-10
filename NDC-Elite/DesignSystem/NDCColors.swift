import SwiftUI

/// Paleta de colores del design system "NDC HQ Alto Rendimiento" (Stitch).
/// Celeste Oscuro = autoridad/coaching profesional; Amarillo = energía/CTAs.
enum NDCColor {
    /// Celeste Oscuro — color primario de marca (#165070)
    static let primary = Color(hex: 0x165070)
    /// Variante profunda del primario (#003953)
    static let primaryDark = Color(hex: 0x003953)
    /// Amarillo de acento para CTAs y celebración de PRs (#FFDE59)
    static let accent = Color(hex: 0xFFDE59)
    /// Fondo principal (blanco puro, estética iOS nativa)
    static let background = Color(hex: 0xFFFFFF)
    /// Superficies secundarias / tarjetas (#F2F2F7)
    static let surface = Color(hex: 0xF2F2F7)
    /// Texto principal (#1A1C1F)
    static let onSurface = Color(hex: 0x1A1C1F)
    /// Texto secundario (#41484D)
    static let onSurfaceVariant = Color(hex: 0x41484D)
    /// Bordes y separadores (#C1C7CE)
    static let outline = Color(hex: 0xC1C7CE)
    /// Error / acciones destructivas (#BA1A1A)
    static let error = Color(hex: 0xBA1A1A)

    /// Chip "RX" — primario al 10% de opacidad como en el diseño
    static let chipBackground = primary.opacity(0.10)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
