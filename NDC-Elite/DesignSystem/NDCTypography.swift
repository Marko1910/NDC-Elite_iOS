import SwiftUI

/// Tipografía del design system NDC HQ.
/// El diseño usa Hanken Grotesk (titulares/stats) e Inter (cuerpo/labels).
/// Mientras no se agreguen las fuentes custom al bundle, usamos el sistema
/// (SF Pro) con los mismos tamaños y pesos — se ve nativo y correcto.
/// Para usar las fuentes reales: añadir los .ttf al target y cambiar `custom`.
///
/// Dynamic Type: `Font.system(size:)` de SwiftUI **sí escala** con el tamaño de
/// letra del usuario (a diferencia de UIKit), así que estos tokens respetan
/// accesibilidad automáticamente. Al pasar a `Font.custom`, usar `relativeTo:`.
enum NDCFont {
    /// display-lg: 34pt / 800 — grandes titulares
    static let displayLG = Font.system(size: 34, weight: .heavy)
    /// headline-md: 24pt / 700 — títulos de sección
    static let headlineMD = Font.system(size: 24, weight: .bold)
    /// headline-sm: 20pt / 600 — subtítulos
    static let headlineSM = Font.system(size: 20, weight: .semibold)
    /// body-lg: 17pt / 400 — cuerpo principal (evita auto-zoom de iOS en inputs)
    static let bodyLG = Font.system(size: 17, weight: .regular)
    /// body-md: 15pt / 400 — cuerpo secundario
    static let bodyMD = Font.system(size: 15, weight: .regular)
    /// label-bold: 13pt / 600 — etiquetas destacadas
    static let labelBold = Font.system(size: 13, weight: .semibold)
    /// label-sm: 12pt / 500 — etiquetas pequeñas / chips
    static let labelSM = Font.system(size: 12, weight: .medium)
    /// stats-xl: 48pt / 800 — datos de rendimiento (PRs, tiempos)
    static let statsXL = Font.system(size: 48, weight: .heavy)
}

/// Espaciado del design system (grid de 8pt)
enum NDCSpacing {
    /// Margen exterior fijo de pantalla (20px)
    static let marginMain: CGFloat = 20
    static let gutter: CGFloat = 16
    static let stackSM: CGFloat = 8
    static let stackMD: CGFloat = 16
    static let stackLG: CGFloat = 24
}

/// Radios de esquina del design system
enum NDCRadius {
    /// Botones, inputs, tarjetas pequeñas
    static let standard: CGFloat = 8
    /// Tarjetas de WOD, headers de perfil
    static let large: CGFloat = 16
}
