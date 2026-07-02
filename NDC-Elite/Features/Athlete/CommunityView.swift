import SwiftUI

/// Tab 4 · Comunidad del atleta — diseño Stitch "Comunidad y Retos" + "Ranking
/// de la Comunidad". Segmentos Retos / Ranking. El Ranking se **anima** al
/// entrar (podio que se eleva, puntos que cuentan, filas escalonadas).
/// (ver FLOWS.md → CommunityView)
///
/// TODO(datos): usa `CommunityData.sample`. Conectar a Supabase: challenges,
/// challenge_participants, achievements, profiles.points, ranking_snapshots.
struct CommunityView: View {
    let profile: Profile
    private let data = CommunityData.sample
    @State private var segment: Segment = .retos
    @State private var retosStore = AthleteChallengesStore()

    enum Segment: String, CaseIterable { case retos = "Retos", ranking = "Ranking" }

    var body: some View {
        NavigationStack {
            VStack(spacing: NDCSpacing.stackMD) {
                segmentedControl
                ScrollView {
                    Group {
                        if segment == .retos {
                            RetosContent(profile: profile, store: retosStore, data: data)
                        } else {
                            RankingContent(data: data)
                        }
                    }
                    .padding(.horizontal, NDCSpacing.marginMain)
                    .padding(.bottom, NDCSpacing.stackLG)
                }
                .scrollIndicators(.hidden)
                .refreshable { await retosStore.load(athleteId: profile.id) }
            }
            .padding(.top, NDCSpacing.stackSM)
            .background(NDCColor.background)
        }
        .tint(NDCColor.primary)
    }

    // MARK: - Segmentado (pill estilo diseño)

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(Segment.allCases, id: \.self) { seg in
                Button {
                    Haptics.selection()
                    withAnimation(.snappy) { segment = seg }
                } label: {
                    Text(seg.rawValue)
                        .font(NDCFont.labelBold)
                        .foregroundStyle(segment == seg ? NDCColor.primary : NDCColor.outline)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background {
                            if segment == seg {
                                RoundedRectangle(cornerRadius: NDCRadius.standard)
                                    .fill(NDCColor.background)
                                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                            }
                        }
                }
                .accessibilityAddTraits(segment == seg ? .isSelected : [])
            }
        }
        .padding(4)
        .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.large))
        .padding(.horizontal, NDCSpacing.marginMain)
    }
}

// MARK: - Segmento Retos (retos reales de Supabase)

private struct RetosContent: View {
    let profile: Profile
    var store: AthleteChallengesStore
    let data: CommunityData
    /// "Ver más" por sección: colapsadas muestran solo los primeros retos.
    @State private var showAllComunidad = false
    @State private var showAllIndividuales = false
    private static let collapsedLimit = 2

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
            LoadStateView(state: store.state, retry: { Task { await store.load(athleteId: profile.id) } }) { retos in
                if retos.challenges.isEmpty {
                    ContentUnavailableView(
                        "Sin retos activos",
                        systemImage: "flag.checkered",
                        description: Text("Tu coach aún no publica retos. ¡Pronto habrá novedades!")
                    )
                } else {
                    VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                        let comunidad = retos.challenges.filter { $0.challengeType == .comunidad }
                        let individuales = retos.challenges.filter { $0.challengeType == .individual }
                        challengeSection("Retos de Comunidad", challenges: comunidad,
                                         retos: retos, showAll: $showAllComunidad)
                        challengeSection("Retos Individuales", challenges: individuales,
                                         retos: retos, showAll: $showAllIndividuales)
                    }
                }
            } skeleton: {
                VStack(spacing: NDCSpacing.stackMD) {
                    SkeletonCard(lines: 3, height: 150)
                    SkeletonCard(lines: 3, height: 150)
                }
            }

            Text("Mis Logros")
                .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            HStack(spacing: NDCSpacing.gutter) {
                ForEach(data.achievements) { badge in
                    VStack(spacing: NDCSpacing.stackSM) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 26))
                            .foregroundStyle(NDCColor.accent)
                            .frame(width: 64, height: 64)
                            .background(NDCColor.primary, in: .circle)
                        Text(badge.title)
                            .font(NDCFont.labelBold)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(NDCColor.onSurface)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                }
            }

            upcomingBanner
        }
        .task { await store.load(athleteId: profile.id) }
    }

    /// Sección de retos con "Ver más": colapsada muestra `collapsedLimit`
    /// tarjetas; el botón alterna a la lista completa (Ver menos).
    @ViewBuilder
    private func challengeSection(_ title: String, challenges: [Challenge],
                                  retos: AthleteChallengesStore.Data,
                                  showAll: Binding<Bool>) -> some View {
        if !challenges.isEmpty {
            let visible = showAll.wrappedValue ? challenges : Array(challenges.prefix(Self.collapsedLimit))
            HStack {
                Text(title).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                if challenges.count > Self.collapsedLimit {
                    Button {
                        Haptics.selection()
                        withAnimation(.snappy) { showAll.wrappedValue.toggle() }
                    } label: {
                        Text(showAll.wrappedValue ? "Ver menos" : "Ver más (\(challenges.count))")
                            .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel(showAll.wrappedValue
                        ? "Ver menos retos de \(title)"
                        : "Ver los \(challenges.count) retos de \(title)")
                }
            }
            ForEach(visible) { ch in
                CommunityChallengeCard(
                    challenge: ch,
                    participantCount: retos.counts[ch.id] ?? 0,
                    isJoined: retos.joined.contains(ch.id),
                    isBusy: store.busyIds.contains(ch.id),
                    onToggle: { Task { await store.toggleJoin(ch, athleteId: profile.id) } }
                )
            }
        }
    }

    private var upcomingBanner: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [NDCColor.primary, NDCColor.primaryDark],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 2) {
                Text("PRÓXIMAMENTE").font(NDCFont.labelBold).foregroundStyle(NDCColor.accent)
                Text("Campeonato de Invierno 2024").font(NDCFont.headlineSM).foregroundStyle(.white)
            }
            .padding(NDCSpacing.stackLG)
        }
        .frame(height: 120)
        .clipShape(.rect(cornerRadius: NDCRadius.large))
    }

}

// MARK: - Tarjeta de reto real (comunidad o individual)

private struct CommunityChallengeCard: View {
    let challenge: Challenge
    let participantCount: Int
    let isJoined: Bool
    let isBusy: Bool
    let onToggle: () -> Void

    private var goalLabel: String {
        "\(Int(challenge.currentValue)) / \(Int(challenge.goalValue)) \(challenge.unit)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Label(challenge.challengeType == .comunidad ? "META GLOBAL" : "RETO INDIVIDUAL",
                  systemImage: challenge.challengeType == .comunidad ? "star.fill" : "flag.fill")
                .font(NDCFont.labelBold)
                .foregroundStyle(NDCColor.accent)
            Text(challenge.title)
                .font(NDCFont.headlineSM).foregroundStyle(.white)
            if let description = challenge.description, !description.isEmpty {
                Text(description).font(NDCFont.bodyMD).foregroundStyle(NDCColor.primaryFixed)
            }
            HStack(alignment: .bottom) {
                Text("\(Int(challenge.currentValue))")
                    .font(NDCFont.displayLG).foregroundStyle(NDCColor.accent)
                Spacer()
                Text("Meta: \(Int(challenge.goalValue)) \(challenge.unit)")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            ProgressTrack(value: challenge.progress, tint: NDCColor.accent,
                          track: NDCColor.primaryDark.opacity(0.4))
            HStack {
                Label("\(participantCount) unidos", systemImage: "person.3.fill")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
                if let endsOn = challenge.endsOn {
                    Text("· hasta el \(endsOn.formatted(.dateTime.day().month()))")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
                }
                Spacer()
            }
            Button {
                Haptics.impact()
                onToggle()
            } label: {
                Text(isBusy ? "…" : (isJoined ? "Inscrito ✓ · Abandonar" : "Unirse al Reto"))
                    .font(NDCFont.bodyLG.weight(.bold))
                    .foregroundStyle(isJoined ? .white : NDCColor.primary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(isJoined ? NDCColor.primaryDark : NDCColor.accent,
                                in: .rect(cornerRadius: NDCRadius.large))
            }
            .disabled(isBusy)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Store de retos del atleta

@MainActor @Observable
final class AthleteChallengesStore {
    struct Data {
        var challenges: [Challenge] = []
        /// Inscritos por reto (para "N unidos").
        var counts: [UUID: Int] = [:]
        /// Retos en los que este atleta ya está inscrito.
        var joined: Set<UUID> = []
    }

    private(set) var state: LoadState<Data> = .loading
    private(set) var busyIds: Set<UUID> = []
    private let repo = ChallengeRepository()

    func load(athleteId: UUID) async {
        if state.value == nil { state = .loading }
        do {
            let challenges = try await repo.activeChallenges()
            let participants = try await repo.participants(challengeIds: challenges.map(\.id))
            var data = Data(challenges: challenges)
            for p in participants {
                data.counts[p.challengeId, default: 0] += 1
                if p.athleteId == athleteId { data.joined.insert(p.challengeId) }
            }
            state = .loaded(data)
        } catch {
            state = .failed("No se pudieron cargar los retos.")
        }
    }

    func toggleJoin(_ challenge: Challenge, athleteId: UUID) async {
        guard case .loaded(let data) = state, !busyIds.contains(challenge.id) else { return }
        busyIds.insert(challenge.id)
        defer { busyIds.remove(challenge.id) }
        do {
            if data.joined.contains(challenge.id) {
                try await repo.leave(challengeId: challenge.id, athleteId: athleteId)
            } else {
                try await repo.join(challengeId: challenge.id, athleteId: athleteId)
                Haptics.notify(.success)
            }
            await load(athleteId: athleteId)
        } catch {
            Haptics.notify(.error)
        }
    }
}

// MARK: - Segmento Ranking (animado)

private struct RankingContent: View {
    let data: CommunityData
    @State private var animate = false

    var body: some View {
        VStack(spacing: NDCSpacing.stackLG) {
            podium
            monthChallenge
            classification
        }
        .onAppear {
            // Re-arranca la animación cada vez que entra al segmento.
            animate = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { animate = true }
        }
    }

    // MARK: Podio animado

    private var podium: some View {
        HStack(alignment: .bottom, spacing: NDCSpacing.gutter) {
            podiumColumn(data.podium[1], maxBar: 70, avatar: 64, delay: 0.05) // #2
            podiumColumn(data.podium[0], maxBar: 104, avatar: 80, delay: 0.0, crown: true) // #1
            podiumColumn(data.podium[2], maxBar: 50, avatar: 64, delay: 0.10) // #3
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func podiumColumn(_ entry: CommunityData.PodiumEntry, maxBar: CGFloat,
                              avatar: CGFloat, delay: Double, crown: Bool = false) -> some View {
        VStack(spacing: NDCSpacing.stackSM) {
            if crown {
                Image(systemName: "crown.fill")
                    .foregroundStyle(NDCColor.accent)
                    .opacity(animate ? 1 : 0)
                    .scaleEffect(animate ? 1 : 0.4)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.5), value: animate)
            }
            ZStack(alignment: .bottomTrailing) {
                NDCAvatarView(urlString: entry.avatarURL, size: avatar)
                Text("\(entry.rank)")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    .frame(width: 24, height: 24)
                    .background(rankColor(entry.rank), in: .circle)
            }
            .scaleEffect(animate ? 1 : 0.6)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(delay + 0.15), value: animate)

            VStack(spacing: 0) {
                Text(entry.name).font(NDCFont.labelBold).foregroundStyle(.white)
                Text("\(animate ? entry.points : 0) pts")
                    .font(crown ? NDCFont.bodyLG.weight(.bold) : NDCFont.labelSM)
                    .foregroundStyle(NDCColor.accent)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 1.0).delay(delay + 0.2), value: animate)
            }

            // Barra del podio que se eleva
            RoundedRectangle(cornerRadius: 6)
                .fill(crown ? NDCColor.accent.opacity(0.3) : .white.opacity(0.12))
                .frame(width: avatar, height: animate ? maxBar : 0)
                .animation(.spring(response: 0.7, dampingFraction: 0.75).delay(delay), value: animate)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puesto \(entry.rank): \(entry.name), \(entry.points) puntos")
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: NDCColor.accent
        case 2: NDCColor.outline
        default: NDCColor.primaryFixed
        }
    }

    // MARK: Reto del mes (barra que se llena)

    private var monthChallenge: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("COMUNIDAD").font(NDCFont.labelSM).foregroundStyle(NDCColor.secondary)
                    Text(data.monthChallenge.title).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                    Text(data.monthChallenge.subtitle).font(NDCFont.bodyMD).foregroundStyle(NDCColor.outline)
                }
                Spacer()
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 24)).foregroundStyle(NDCColor.primary)
                    .frame(width: 48, height: 48)
                    .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.standard))
            }
            HStack {
                Text(data.monthChallenge.currentLabel)
                Spacer()
                Text(data.monthChallenge.goalLabel)
            }
            .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
            ProgressTrack(value: animate ? data.monthChallenge.progress : 0,
                          tint: NDCColor.accent, track: NDCColor.surfaceStrong, height: 12,
                          animation: .easeOut(duration: 1.1).delay(0.3), trigger: animate)
            Text(data.monthChallenge.remaining)
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                .frame(maxWidth: .infinity)
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large)
            .stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
    }

    // MARK: Clasificación (entrada escalonada)

    private var classification: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack {
                Text("Clasificación").font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Spacer()
                Text("Ver todo").font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
            }
            ForEach(Array(data.ranking.enumerated()), id: \.element.id) { index, row in
                RankRowView(row: row)
                    .opacity(animate ? 1 : 0)
                    .offset(y: animate ? 0 : 16)
                    .animation(.easeOut(duration: 0.4).delay(0.5 + Double(index) * 0.08), value: animate)
            }
        }
    }
}

private struct RankRowView: View {
    let row: CommunityData.RankRow

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            Text("\(row.rank)")
                .font(NDCFont.headlineSM).foregroundStyle(NDCColor.outline)
                .frame(width: 24)
            NDCAvatarView(urlString: row.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Text("\(row.points) pts").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            VStack(spacing: 0) {
                Image(systemName: row.delta > 0 ? "arrowtriangle.up.fill"
                      : row.delta < 0 ? "arrowtriangle.down.fill" : "minus")
                    .font(.system(size: 12))
                Text(row.delta == 0 ? "0" : (row.delta > 0 ? "+\(row.delta)" : "\(row.delta)"))
                    .font(NDCFont.labelSM)
            }
            .foregroundStyle(row.delta > 0 ? .green : row.delta < 0 ? NDCColor.error : NDCColor.outline)
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Puesto \(row.rank), \(row.name), \(row.points) puntos, cambio \(row.delta)")
    }
}

// MARK: - Barra de progreso (con animación opcional)

private struct ProgressTrack: View {
    let value: Double
    var tint: Color = NDCColor.primary
    var track: Color = NDCColor.surfaceStrong
    var height: CGFloat = 10
    var animation: Animation? = nil
    var trigger: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint)
                    .frame(width: geo.size.width * min(max(value, 0), 1))
                    .animation(animation, value: trigger)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

// MARK: - Datos de muestra (a reemplazar por fetch de Supabase)

private struct CommunityData {
    struct IndividualChallenge: Identifiable {
        let id = UUID()
        let kind: String
        let kindIcon: String
        let title: String
        let badge: String
        let icon: String
        let ringProgress: Double?
        let description: String
        let footer: String
        let cta: String
    }
    struct Achievement: Identifiable { let id = UUID(); let icon: String; let title: String }
    struct PodiumEntry: Identifiable {
        let id = UUID(); let rank: Int; let name: String; let points: Int; let avatarURL: String?
    }
    struct RankRow: Identifiable {
        let id = UUID(); let rank: Int; let name: String; let points: Int; let delta: Int; let avatarURL: String?
    }
    struct CommunityChallenge { let title, current, goal, remaining: String; let progress: Double }
    struct MonthChallenge {
        let title, subtitle, currentLabel, goalLabel, remaining: String; let progress: Double
    }

    let communityChallenge: CommunityChallenge
    let individualChallenges: [IndividualChallenge]
    let achievements: [Achievement]
    let podium: [PodiumEntry]
    let monthChallenge: MonthChallenge
    let ranking: [RankRow]
    let unreadCount: Int

    static let sample = CommunityData(
        communityChallenge: CommunityChallenge(
            title: "Reto de Comunidad: 1 Millón de Burpees",
            current: "742k", goal: "1,000,000",
            remaining: "¡Faltan 258,000 burpees para alcanzar la meta colectiva de este mes!",
            progress: 0.742),
        individualChallenges: [
            IndividualChallenge(kind: "Desafío Semanal", kindIcon: "figure.run",
                title: "Running Sunday - 5 KM", badge: "Domingo", icon: "map.fill",
                ringProgress: nil,
                description: "Completa una carrera de 5km este domingo con la comunidad.",
                footer: "45 atletas ya inscritos", cta: "Unirse al Reto"),
            IndividualChallenge(kind: "Habilidad", kindIcon: "timer",
                title: "Double Unders", badge: "4 Días rest.", icon: "bolt.fill",
                ringProgress: 0.0,
                description: "Objetivo: Completar 500 saltos dobles esta semana.",
                footer: "Progreso personal: 0 / 500", cta: "Continuar")
        ],
        achievements: [
            Achievement(icon: "sun.max.fill", title: "Early Bird"),
            Achievement(icon: "bolt.fill", title: "PR Crusher"),
            Achievement(icon: "checkmark.seal.fill", title: "Consistent")
        ],
        podium: [
            PodiumEntry(rank: 1, name: "Elena R.", points: 2890, avatarURL: nil),
            PodiumEntry(rank: 2, name: "David G.", points: 2450, avatarURL: nil),
            PodiumEntry(rank: 3, name: "Lucía M.", points: 2120, avatarURL: nil)
        ],
        monthChallenge: MonthChallenge(
            title: "Reto del Mes", subtitle: "Max RM Clean Colectivo",
            currentLabel: "7,450 kg", goalLabel: "10,000 kg",
            remaining: "¡Faltan 2,550 kg para el objetivo de Marzo!", progress: 0.745),
        ranking: [
            RankRow(rank: 4, name: "Marcos T.", points: 1980, delta: -1, avatarURL: nil),
            RankRow(rank: 5, name: "Ricardo S.", points: 1850, delta: 3, avatarURL: nil),
            RankRow(rank: 6, name: "Beatriz O.", points: 1720, delta: 0, avatarURL: nil),
            RankRow(rank: 7, name: "Carlos V.", points: 1695, delta: 1, avatarURL: nil)
        ],
        unreadCount: 2
    )
}

#Preview {
    CommunityView(profile: .preview)
}
