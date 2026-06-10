import SwiftUI

// MARK: - Botones del design system

/// Botón primario: fondo Celeste Oscuro, texto blanco, peso heavy.
struct NDCPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NDCFont.bodyLG.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.standard))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Botón de acción/acento: fondo Amarillo, texto Celeste Oscuro.
/// Usado para "Empezar", "Guardar", registrar resultados.
struct NDCAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NDCFont.bodyLG.weight(.bold))
            .foregroundStyle(NDCColor.primaryDark)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// Botón fantasma: borde Celeste Oscuro 1pt, fondo transparente.
struct NDCGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NDCFont.bodyLG.weight(.semibold))
            .foregroundStyle(NDCColor.primary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .overlay(
                RoundedRectangle(cornerRadius: NDCRadius.standard)
                    .stroke(NDCColor.primary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == NDCPrimaryButtonStyle {
    static var ndcPrimary: NDCPrimaryButtonStyle { .init() }
}
extension ButtonStyle where Self == NDCAccentButtonStyle {
    static var ndcAccent: NDCAccentButtonStyle { .init() }
}
extension ButtonStyle where Self == NDCGhostButtonStyle {
    static var ndcGhost: NDCGhostButtonStyle { .init() }
}

// MARK: - Chips

/// Chip de categoría estilo pill ("RX", "Escalado", "Fuerza").
struct NDCChip: View {
    let text: String
    var color: Color = NDCColor.primary

    var body: some View {
        Text(text)
            .font(NDCFont.labelSM)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.10), in: .capsule)
    }
}

// MARK: - Tarjeta

/// Contenedor de tarjeta estándar del design system.
struct NDCCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(NDCSpacing.gutter)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }
}
