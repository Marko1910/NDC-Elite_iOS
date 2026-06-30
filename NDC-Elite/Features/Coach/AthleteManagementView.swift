import SwiftUI

/// Tab 3 · Atletas del coach — diseño Stitch "Gestión de Atletas".
/// CTA tomar asistencia · búsqueda · filtro por nivel/lesión · lista de miembros
/// activos con acceso al perfil. (ver FLOWS.md → AthleteManagementView)
///
/// TODO(datos): hoy usa `AthleteListData.sample`. Conectar a Supabase:
/// profiles (atletas, filtros nivel) + injuries (lesión activa).
struct AthleteManagementView: View {
    let profile: Profile
    private let all = AthleteListData.sample
    @State private var query = ""
    @State private var filter: AthleteFilter = .todos
    @State private var showAttendance = false
    @State private var selectedAthlete: String?
    @State private var showInvite = false

    enum AthleteFilter: String, CaseIterable {
        case todos = "Todos", basico = "Básico", intermedio = "Intermedio"
        case avanzado = "Avanzado", lesion = "Con Lesión"
    }

    private var filtered: [AthleteListData.Member] {
        all.filter { m in
            let matchesQuery = query.isEmpty || m.name.localizedCaseInsensitiveContains(query)
            let matchesFilter: Bool
            switch filter {
            case .todos: matchesFilter = true
            case .lesion: matchesFilter = m.injury != nil
            default: matchesFilter = m.level.lowercased() == filter.rawValue.lowercased()
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
                    HStack {
                        Text("MIEMBROS ACTIVOS").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                        Spacer()
                        Text("\(all.count) Total").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                    }
                    if filtered.isEmpty {
                        ContentUnavailableView("Sin atletas", systemImage: "person.slash",
                                               description: Text("No hay atletas en este filtro."))
                            .padding(.top, NDCSpacing.stackLG)
                    } else {
                        ForEach(filtered) { member in
                            MemberRow(member: member) { selectedAthlete = member.name }
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
            .sheet(isPresented: $showInvite) { InviteAthleteView() }
            .navigationDestination(item: $selectedAthlete) { name in
                CoachAthleteProfileView(athleteName: name)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Haptics.impact(); showInvite = true } label: {
                        Image(systemName: "person.badge.plus")
                    }
                    .accessibilityLabel("Invitar atleta")
                }
            }
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

// MARK: - Fila de miembro

private struct MemberRow: View {
    let member: AthleteListData.Member
    let onProfile: () -> Void

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: member.avatarURL, size: 52)
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name).font(NDCFont.bodyLG.weight(.bold)).foregroundStyle(NDCColor.onSurface)
                HStack(spacing: NDCSpacing.stackSM) {
                    Text(member.level.uppercased())
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.primary)
                        .fixedSize()
                    if let injury = member.injury {
                        Label(injury, systemImage: "exclamationmark.triangle.fill")
                            .font(NDCFont.labelSM).foregroundStyle(NDCColor.error)
                            .lineLimit(1)
                    } else {
                        Text(member.since).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
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
            .accessibilityLabel("Ver perfil de \(member.name)")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Datos de muestra

private enum AthleteListData {
    struct Member: Identifiable {
        let id = UUID()
        let name, level, since: String
        var injury: String? = nil
        var avatarURL: String? = nil
    }

    static let sample: [Member] = [
        Member(name: "Sofía Martínez", level: "Avanzado", since: "Desde Mayo 2023"),
        Member(name: "Carlos Rivera", level: "Intermedio", since: "Desde Marzo 2023", injury: "Lesión de Hombro"),
        Member(name: "Lucía Gómez", level: "Básico", since: "Desde Enero 2024"),
        Member(name: "Mateo Santos", level: "Avanzado", since: "Desde Octubre 2022"),
        Member(name: "Elena Ruiz", level: "Intermedio", since: "Desde Julio 2023"),
        Member(name: "Diego Flores", level: "Básico", since: "Desde Febrero 2024")
    ]
}

#Preview {
    AthleteManagementView(profile: .preview)
}
