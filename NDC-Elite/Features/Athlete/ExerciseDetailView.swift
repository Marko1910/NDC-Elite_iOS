import SwiftUI

/// Ejercicio de la biblioteca técnica (modelo de muestra; futuro: tabla `exercises`
/// + `exercise_technique_steps`, con `video_url` de YouTube que sube el coach).
struct LibraryExercise: Identifiable, Hashable {
    let id: UUID
    let name: String
    let subtitle: String
    let category: ExerciseCategory
    let level: AthleteLevel
    /// Enlace de YouTube que sube el coach (cualquier formato).
    let youtubeURL: String
    let summary: String
    /// En qué se mide la marca de este ejercicio (kg, tiempo, reps…).
    /// Define la unidad al registrar/corregir PRs (`default_score_type`).
    let scoreType: ScoreType
    let steps: [Step]

    init(id: UUID = UUID(), name: String, subtitle: String, category: ExerciseCategory,
         level: AthleteLevel, youtubeURL: String, summary: String,
         scoreType: ScoreType = .peso, steps: [Step]) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.level = level
        self.youtubeURL = youtubeURL
        self.summary = summary
        self.scoreType = scoreType
        self.steps = steps
    }

    struct Step: Hashable {
        let title: String
        let detail: String
    }
}

/// Detalle de un ejercicio — diseño Stitch "Biblioteca Técnica".
/// Reproduce el video del coach (YouTube) **dentro de la app**, muestra la
/// descripción y los pasos de técnica, y permite registrar el PR.
/// (ver FLOWS.md → ExerciseDetailView)
struct ExerciseDetailView: View {
    let exercise: LibraryExercise
    @State private var showLogPr = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                videoPlayer
                heading
                summary
                steps
                // Los PR solo aplican a levantamientos: el botón aparece
                // únicamente si el ejercicio se mide en peso.
                if exercise.scoreType == .peso {
                    registerButton
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackMD)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogPr) { LogPrSheet() }
    }

    // MARK: - Video (YouTube embebido)

    @ViewBuilder
    private var videoPlayer: some View {
        if let id = YouTube.videoID(from: exercise.youtubeURL) {
            YouTubeThumbnailPlayer(videoID: id)
                .aspectRatio(16 / 9, contentMode: .fit)
                .clipShape(.rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.1), radius: 8, y: 3)
                .accessibilityLabel("Video de técnica de \(exercise.name)")
        } else {
            // Sin video aún (el coach no ha subido el enlace).
            ZStack {
                NDCColor.surfaceStrong
                VStack(spacing: NDCSpacing.stackSM) {
                    Image(systemName: "video.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(NDCColor.outline)
                    Text("Video próximamente")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.outline)
                }
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(.rect(cornerRadius: NDCRadius.large))
        }
    }

    // MARK: - Encabezado

    private var heading: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(exercise.name)
                .font(NDCFont.headlineMD)
                .foregroundStyle(NDCColor.primary)
            Text(exercise.subtitle.uppercased())
                .font(NDCFont.labelSM)
                .foregroundStyle(NDCColor.outline)
                .tracking(1)
            HStack(spacing: NDCSpacing.stackSM) {
                NDCChip(text: exercise.category.displayName)
                NDCChip(text: exercise.level.displayName, color: NDCColor.onSurfaceVariant)
            }
        }
    }

    // MARK: - Descripción

    private var summary: some View {
        Text(exercise.summary)
            .font(NDCFont.bodyMD)
            .foregroundStyle(NDCColor.onSurfaceVariant)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Pasos de técnica

    private var steps: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("Técnica paso a paso")
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.primary)
            ForEach(Array(exercise.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: NDCSpacing.gutter) {
                    Text("\(index + 1)")
                        .font(NDCFont.labelBold)
                        .foregroundStyle(NDCColor.primary)
                        .frame(width: 32, height: 32)
                        .background(NDCColor.primary.opacity(0.12), in: .circle)
                    (Text(step.title + ": ").font(NDCFont.bodyMD.weight(.bold)).foregroundColor(NDCColor.onSurface)
                     + Text(step.detail).font(NDCFont.bodyMD).foregroundColor(NDCColor.onSurfaceVariant))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: - Registrar PR

    private var registerButton: some View {
        Button {
            Haptics.impact()
            showLogPr = true
        } label: {
            Label("Registrar PR Actual", systemImage: "chart.bar.fill")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                .shadow(color: NDCColor.primaryDark.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.top, NDCSpacing.stackSM)
        .accessibilityHint("Registra tu marca para este ejercicio")
    }
}

#Preview {
    NavigationStack {
        ExerciseDetailView(exercise: LibraryExercise(
            name: "Back Squat",
            subtitle: "Sentadilla por detrás",
            category: .fuerza,
            level: .basico,
            youtubeURL: "https://www.youtube.com/watch?v=nEsZViY3EJ4",
            summary: "Ejercicio base de fuerza de tren inferior.",
            steps: [.init(title: "Setup", detail: "Pies a la anchura de los hombros.")]
        ))
    }
}
