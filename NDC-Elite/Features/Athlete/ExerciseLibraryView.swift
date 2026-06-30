import SwiftUI

/// Biblioteca Técnica de Ejercicios — diseño Stitch "Biblioteca Técnica".
/// Intuitiva: búsqueda por nombre + filtro por categoría + lista. Cada ejercicio
/// abre su detalle con el video del coach (YouTube in-app), descripción y pasos.
/// El coach mantiene esta biblioteca subiendo enlaces de YouTube.
/// (ver FLOWS.md → ExerciseLibraryView)
///
/// TODO(datos): hoy usa `ExerciseLibrary.sample`. Conectar a Supabase:
/// `exercises` + `exercise_technique_steps` (con `video_url`).
struct ExerciseLibraryView: View {
    @State private var query = ""
    @State private var category: ExerciseCategory?

    private let all = ExerciseLibrary.sample

    private var filtered: [LibraryExercise] {
        all.filter { ex in
            (category == nil || ex.category == category)
            && (query.isEmpty
                || ex.name.localizedCaseInsensitiveContains(query)
                || ex.subtitle.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                categoryFilter
                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { ex in
                        NavigationLink(value: ex) {
                            ExerciseRow(exercise: ex)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackSM)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Biblioteca Técnica")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Buscar técnica (ej. Snatch, Clean...)")
        .navigationDestination(for: LibraryExercise.self) { ex in
            ExerciseDetailView(exercise: ex)
        }
    }

    // MARK: - Filtro de categorías

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                filterChip(title: "Todas", selected: category == nil) { category = nil }
                ForEach(ExerciseCategory.allCases, id: \.self) { cat in
                    filterChip(title: cat.displayName, selected: category == cat) {
                        category = (category == cat) ? nil : cat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func filterChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(NDCFont.labelBold)
                .foregroundStyle(selected ? .white : NDCColor.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "Sin resultados",
            systemImage: "magnifyingglass",
            description: Text("No encontramos ejercicios para “\(query)”.")
        )
        .padding(.top, NDCSpacing.stackLG)
    }
}

// MARK: - Fila de ejercicio

private struct ExerciseRow: View {
    let exercise: LibraryExercise

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            ZStack {
                NDCColor.primary.opacity(0.10)
                Image(systemName: exercise.category.symbol)
                    .font(.system(size: 22))
                    .foregroundStyle(NDCColor.primary)
            }
            .frame(width: 56, height: 56)
            .clipShape(.rect(cornerRadius: NDCRadius.standard))

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(NDCFont.bodyLG.weight(.semibold))
                    .foregroundStyle(NDCColor.onSurface)
                Text(exercise.subtitle)
                    .font(NDCFont.labelSM)
                    .foregroundStyle(NDCColor.outline)
                NDCChip(text: exercise.category.displayName)
                    .padding(.top, 2)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: NDCRadius.large)
                .stroke(NDCColor.outline.opacity(0.20), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exercise.name), \(exercise.category.displayName), \(exercise.level.displayName)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Icono por categoría (SF Symbols)

extension ExerciseCategory {
    var symbol: String {
        switch self {
        case .fuerza: "dumbbell.fill"
        case .gimnasia: "figure.gymnastics"
        case .endurance: "figure.run"
        case .movilidad: "figure.cooldown"
        case .olimpico: "figure.strengthtraining.traditional"
        }
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

enum ExerciseLibrary {
    /// Los `youtubeURL` son **placeholders**; el coach los reemplaza con sus
    /// enlaces reales de YouTube. El reproductor acepta cualquier formato.
    static let sample: [LibraryExercise] = [
        LibraryExercise(
            name: "Back Squat",
            subtitle: "Sentadilla por detrás",
            category: .fuerza,
            level: .basico,
            youtubeURL: "https://www.youtube.com/watch?v=nEsZViY3EJ4",
            summary: "Ejercicio base de fuerza de tren inferior. Trabaja cuádriceps, glúteos y core con la barra apoyada sobre los trapecios.",
            steps: [
                .init(title: "Setup", detail: "Pies a la anchura de los hombros, barra apoyada firmemente sobre los trapecios."),
                .init(title: "Descenso", detail: "Inicia rompiendo la cadera, manteniendo el pecho erguido y las rodillas alineadas con los pies."),
                .init(title: "Profundidad", detail: "El pliegue de la cadera debe bajar más que el tope de la rodilla.")
            ]
        ),
        LibraryExercise(
            name: "Snatch",
            subtitle: "Arranque olímpico",
            category: .olimpico,
            level: .avanzado,
            youtubeURL: "https://youtu.be/9xQp2sldyts",
            summary: "Levantamiento olímpico que lleva la barra del suelo a por encima de la cabeza en un solo movimiento. Exige potencia y movilidad.",
            steps: [
                .init(title: "Primer tirón", detail: "Despega la barra del suelo controlando la espalda neutra y los hombros sobre la barra."),
                .init(title: "Segundo tirón", detail: "Extiende cadera y rodillas de forma explosiva; encoge bajo la barra."),
                .init(title: "Recepción", detail: "Recibe en sentadilla profunda con la barra estable por encima de la cabeza.")
            ]
        ),
        LibraryExercise(
            name: "Muscle Up",
            subtitle: "Transición en anillas/barra",
            category: .gimnasia,
            level: .avanzado,
            youtubeURL: "https://www.youtube.com/watch?v=astSQRcAU2g",
            summary: "Combina una dominada explosiva con un fondo. Requiere fuerza de tirón y empuje y una transición técnica.",
            steps: [
                .init(title: "Kipping", detail: "Genera ritmo con el hollow-arch manteniendo tensión en el core."),
                .init(title: "Tirón alto", detail: "Tira los codos hacia atrás llevando el pecho por encima de la barra/anillas."),
                .init(title: "Transición", detail: "Gira las muñecas y termina con un fondo a la extensión completa.")
            ]
        ),
        LibraryExercise(
            name: "Peso Muerto",
            subtitle: "Deadlift",
            category: .fuerza,
            level: .intermedio,
            youtubeURL: "https://youtu.be/op9kVnSso6Q",
            summary: "Patrón de bisagra de cadera que desarrolla la cadena posterior. Clave para la fuerza total y la prevención de lesiones lumbares.",
            steps: [
                .init(title: "Setup", detail: "Barra sobre el medio del pie, espalda neutra, hombros ligeramente por delante de la barra."),
                .init(title: "Tirón", detail: "Empuja el suelo con las piernas manteniendo la barra pegada al cuerpo."),
                .init(title: "Bloqueo", detail: "Extiende cadera y rodillas a la vez sin hiperextender la lumbar.")
            ]
        ),
        LibraryExercise(
            name: "Double Unders",
            subtitle: "Dobles a la comba",
            category: .endurance,
            level: .intermedio,
            youtubeURL: "https://www.youtube.com/watch?v=82jNjDS19lg",
            summary: "La cuerda pasa dos veces por salto. Mejora la coordinación, la resistencia y la economía de movimiento en metcons.",
            steps: [
                .init(title: "Postura", detail: "Codos pegados al cuerpo, salto pequeño y rápido desde la punta de los pies."),
                .init(title: "Muñecas", detail: "El giro viene de las muñecas, no de los brazos; mantén el ritmo constante."),
                .init(title: "Timing", detail: "Un solo salto, dos giros: sincroniza el doble giro en el punto más alto.")
            ]
        )
    ]
}

#Preview {
    NavigationStack { ExerciseLibraryView() }
}
