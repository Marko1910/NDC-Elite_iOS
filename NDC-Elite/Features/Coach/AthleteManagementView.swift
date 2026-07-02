import SwiftUI

/// Tab 3 · Atletas del coach — diseño Stitch "Gestión de Atletas".
/// CTA tomar asistencia · búsqueda · filtro por nivel/lesión · lista de miembros
/// activos con acceso al perfil. (ver FLOWS.md → AthleteManagementView)
///
/// Lista real: `profiles` (role = atleta, activos) + `injuries` sin resolver
/// para el indicador y el filtro "Con Lesión".
struct AthleteManagementView: View {
    let profile: Profile
    @State private var store = AthleteManagementStore()
    @State private var query = ""
    @State private var filter: AthleteFilter = .todos
    @State private var showAttendance = false
    @State private var selectedAthlete: Profile?
    @State private var showInvite = false

    enum AthleteFilter: String, CaseIterable {
        case todos = "Todos", basico = "Principiante", intermedio = "Intermedio"
        case avanzado = "Avanzado", lesion = "Con Lesión"

        var level: AthleteLevel? {
            switch self {
            case .basico: .basico
            case .intermedio: .intermedio
            case .avanzado: .avanzado
            case .todos, .lesion: nil
            }
        }
    }

    private func filtered(_ data: AthleteManagementStore.Data) -> [Profile] {
        data.athletes.filter { athlete in
            let matchesQuery = query.isEmpty || athlete.fullName.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool = switch filter {
            case .todos: true
            case .lesion: data.injured.contains(athlete.id)
            default: athlete.level == filter.level
            }
            return matchesQuery && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                    takeAttendanceCTA
                    filterChips
                    LoadStateView(state: store.state, retry: { Task { await store.load() } }) { data in
                        let visible = filtered(data)
                        HStack {
                            Text("MIEMBROS ACTIVOS").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                            Spacer()
                            Text("\(data.athletes.count) Total").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                        }
                        if visible.isEmpty {
                            ContentUnavailableView("Sin atletas", systemImage: "person.slash",
                                                   description: Text("No hay atletas en este filtro."))
                                .padding(.top, NDCSpacing.stackLG)
                        } else {
                            ForEach(visible) { athlete in
                                MemberRow(athlete: athlete, hasInjury: data.injured.contains(athlete.id)) {
                                    selectedAthlete = athlete
                                }
                            }
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackSM) {
                            SkeletonCard(lines: 2, height: 76)
                            SkeletonCard(lines: 2, height: 76)
                            SkeletonCard(lines: 2, height: 76)
                        }
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, NDCSpacing.stackLG)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Atletas")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Buscar atletas por nombre...")
            .sheet(isPresented: $showAttendance) { AttendanceControlView() }
            .sheet(isPresented: $showInvite) { GenerateInviteCodeView() }
            .navigationDestination(item: $selectedAthlete) { athlete in
                CoachAthleteProfileView(athlete: athlete)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        ClassScheduleView()
                    } label: {
                        Image(systemName: "calendar")
                    }
                    .accessibilityLabel("Horario de clases")

                    Button { Haptics.impact(); showInvite = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Invitar atleta")
                }
            }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
        .tint(NDCColor.primary)
    }

    private var takeAttendanceCTA: some View {
        Button {
            Haptics.impact()
            showAttendance = true
        } label: {
            HStack(spacing: NDCSpacing.gutter) {
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 24)).foregroundStyle(NDCColor.onAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tomar Asistencia").font(NDCFont.headlineSM).foregroundStyle(NDCColor.onAccent)
                    Text("Registra atletas en la clase actual").font(NDCFont.labelSM).foregroundStyle(NDCColor.onAccent.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(NDCColor.onAccent)
            }
            .padding(NDCSpacing.stackLG)
            .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
        }
        .accessibilityHint("Abre el registro de asistencia de la clase actual")
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(AthleteFilter.allCases, id: \.self) { f in
                    Button {
                        Haptics.selection()
                        filter = f
                    } label: {
                        HStack(spacing: 4) {
                            if f == .lesion { Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)) }
                            Text(f.rawValue)
                        }
                        .font(NDCFont.labelBold)
                        .foregroundStyle(filter == f ? .white : NDCColor.primary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(filter == f ? NDCColor.primary : NDCColor.primary.opacity(0.10), in: .capsule)
                    }
                    .accessibilityAddTraits(filter == f ? .isSelected : [])
                }
            }
        }
    }
}

// MARK: - Store (atletas reales + lesiones activas)

@MainActor @Observable
final class AthleteManagementStore {
    struct Data {
        let athletes: [Profile]
        let injured: Set<UUID>
    }

    private(set) var state: LoadState<Data> = .loading
    private let repo = CoachRepository()

    func load() async {
        state = .loading
        do {
            async let athletesTask = repo.athletes()
            async let injuredTask = repo.athletesWithActiveInjury()
            state = .loaded(Data(athletes: try await athletesTask, injured: try await injuredTask))
        } catch {
            state = .failed("No se pudo cargar la lista de atletas.")
        }
    }
}

// MARK: - Fila de miembro

private struct MemberRow: View {
    let athlete: Profile
    let hasInjury: Bool
    let onProfile: () -> Void

    private var sinceLabel: String {
        "Desde \(athlete.memberSince.formatted(.dateTime.month(.wide).year()).capitalized)"
    }

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: athlete.avatarURL, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(athlete.fullName).font(NDCFont.bodyLG.weight(.bold)).foregroundStyle(NDCColor.onSurface)
                HStack(spacing: NDCSpacing.stackSM) {
                    Text(athlete.level.displayName.uppercased())
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.primary)
                        .fixedSize()
                    if hasInjury {
                        Label("Lesión activa", systemImage: "exclamationmark.triangle.fill")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.error)
                            .lineLimit(1)
                    } else {
                        Text(sinceLabel).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            Button {
                Haptics.impact(.light)
                onProfile()
            } label: {
                Text("Ver Perfil")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(NDCColor.surface, in: .capsule)
            }
            .accessibilityLabel("Ver perfil de \(athlete.fullName)")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    AthleteManagementView(profile: .preview)
}
