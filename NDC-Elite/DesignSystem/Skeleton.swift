import SwiftUI

// MARK: - Estado de carga genérico

/// Estado de una vista que carga datos de la red (patrón loading/loaded/failed).
/// La UI muestra skeleton en `.loading`, datos en `.loaded`, error en `.failed`.
enum LoadState<Value> {
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case let .loaded(v) = self { return v }
        return nil
    }
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

// MARK: - Shimmer (brillo animado del skeleton)

/// Efecto shimmer: una banda de luz que recorre el contenido en bucle.
private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.55), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width * 1.4)
                    .offset(x: geo.size.width * phase)
                    .blendMode(.plusLighter)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1.4
                }
            }
    }
}

extension View {
    /// Aplica el brillo de carga (úsalo sobre formas/placeholders del skeleton).
    func shimmering() -> some View { modifier(Shimmer()) }
}

// MARK: - Bloque base de skeleton

/// Rectángulo redondeado gris que representa contenido aún no cargado.
struct SkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var cornerRadius: CGFloat = 6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(NDCColor.surfaceStrong)
            .frame(width: width, height: height)
            .shimmering()
            .accessibilityHidden(true)
    }
}

/// Tarjeta-placeholder estándar (para listas/cards mientras cargan).
struct SkeletonCard: View {
    var lines: Int = 3
    var height: CGFloat = 96

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            SkeletonBlock(width: 120, height: 16)
            ForEach(0..<lines, id: \.self) { i in
                SkeletonBlock(width: i == lines - 1 ? 160 : nil, height: 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }
}

// MARK: - Contenedor que cambia entre skeleton / datos / error

/// Renderiza skeleton mientras carga, el contenido al cargar, o un error con
/// botón de reintentar. Mantiene el cableado de cada pantalla uniforme.
struct LoadStateView<Value, Content: View, Skeleton: View>: View {
    let state: LoadState<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content
    @ViewBuilder let skeleton: () -> Skeleton

    var body: some View {
        switch state {
        case .loading:
            skeleton().transition(.opacity)
        case .loaded(let value):
            content(value).transition(.opacity)
        case .failed(let message):
            ContentUnavailableView {
                Label("No se pudo cargar", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Reintentar") { retry() }
                    .buttonStyle(.borderedProminent)
                    .tint(NDCColor.primary)
            }
            .transition(.opacity)
        }
    }
}
