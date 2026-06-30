import UIKit

/// Feedback háptico estándar de la app (patrón Apple HIG / skill mobile-ios-design).
/// Usar en CTAs y confirmaciones para dar respuesta táctil nativa.
enum Haptics {
    /// Toque al pulsar un botón/acción (CTA). `.light` para acciones menores.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    /// Resultado de una operación: `.success`, `.warning`, `.error`.
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Cambio de selección (segmentos, pickers).
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
