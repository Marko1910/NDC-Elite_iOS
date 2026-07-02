import SwiftUI

/// Comunidad (coach) — pantalla dedicada de retos. Se llega desde el botón
/// "Comunidad" en Progreso. El coach crea retos (comunidad/individual), ve
/// **quiénes se han unido** (nombre + foto + fecha), cambia la fecha límite
/// de cada reto o lo elimina. El atleta se une desde su tab Comunidad.
/// (`challenges` + `challenge_participants`, RLS is_coach()).
struct ChallengeManagementView: View {
    let profile: Profile
    @State private var store = CoachChallengesStore()
    @State private var showEditor = false
    @State private var editingDeadline: Challenge?
    @State private var challengePendingDelete: Challenge?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
                LoadStateView(state: store.state, retry: { Task { await store.load() } }) { items in
                    if items.isEmpty {
                        ContentUnavailableView(
                            "Sin retos activos",
                            systemImage: "flag.checkered",
                            description: Text("Crea el primer reto con el botón +. Los atletas podrán unirse desde su tab Comunidad.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        ForEach(items) { item in
                            ChallengeCoachCard(
                                item: item,
                                onEditDeadline: { editingDeadline = item.challenge },
                                onDelete: { challengePendingDelete = item.challenge }
                            )
                        }
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackMD) {
                        SkeletonCard(lines: 3, height: 140)
                        SkeletonCard(lines: 3, height: 140)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackSM)
            .padding(.bottom, NDCSpacing.stackLG)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Comunidad")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.impact(.light)
                    showEditor = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Crear reto")
            }
        }
        .sheet(isPresented: $showEditor, onDismiss: { Task { await store.load() } }) {
            ChallengeEditorSheet(profile: profile)
        }
        .sheet(item: $editingDeadline) { challenge in
            DeadlineEditorSheet(challenge: challenge) { newDate in
                Task { await store.updateDeadline(challenge, endsOn: newDate) }
            }
        }
        .confirmationDialog(
            "¿Eliminar el reto \(challengePendingDelete?.title ?? "")?",
            isPresented: Binding(get: { challengePendingDelete != nil },
                                 set: { if !$0 { challengePendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Eliminar", role: .destructive) {
                if let challenge = challengePendingDelete {
                    Task { await store.delete(challenge) }
                }
                challengePendingDelete = nil
            }
            Button("Cancelar", role: .cancel) { challengePendingDelete = nil }
        } message: {
            Text("También se quitará a los atletas inscritos.")
        }
        .task { await store.load() }
        .refreshable { await store.load() }
    }
}

// MARK: - Tarjeta de reto (vista coach: inscritos con nombre y foto)

private struct ChallengeCoachCard: View {
    let item: CoachChallengesStore.Item
    let onEditDeadline: () -> Void
    let onDelete: () -> Void
    /// Los inscritos se muestran siempre: es lo primero que el coach quiere ver.
    @State private var showParticipants = true

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                NDCChip(text: item.challenge.challengeType == .comunidad ? "Comunidad" : "Individual")
                Spacer()
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash").foregroundStyle(NDCColor.error)
                }
                .accessibilityLabel("Eliminar reto \(item.challenge.title)")
            }
            Text(item.challenge.title).font(NDCFont.headlineSM).foregroundStyle(NDCColor.onSurface)
            Text("Meta: \(Int(item.challenge.goalValue)) \(item.challenge.unit)")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)

            // Fecha límite editable
            Button {
                Haptics.impact(.light)
                onEditDeadline()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                    Text(item.challenge.endsOn.map { "Hasta el \($0.formatted(.dateTime.day().month(.wide)))" } ?? "Sin fecha límite")
                    Image(systemName: "pencil").font(.system(size: 11))
                }
                .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(NDCColor.primary.opacity(0.1), in: .capsule)
            }
            .accessibilityLabel("Cambiar fecha límite de \(item.challenge.title)")

            Divider()

            Button {
                Haptics.selection()
                withAnimation(.snappy) { showParticipants.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                    Text("\(item.participants.count) atletas unidos")
                    Spacer()
                    Image(systemName: showParticipants ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                }
                .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
            }

            if showParticipants {
                if item.participants.isEmpty {
                    Text("Nadie se ha unido todavía.")
                        .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                } else {
                    ForEach(item.participants) { p in
                        HStack(spacing: NDCSpacing.stackSM) {
                            NDCAvatarView(urlString: p.avatarURL, size: 30)
                            Text(p.fullName).font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                            Spacer()
                            Text("desde el \(p.joinedAt.formatted(.dateTime.day().month()))")
                                .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }
}

// MARK: - Editor de fecha límite

private struct DeadlineEditorSheet: View {
    let challenge: Challenge
    let onSave: (Date?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var hasDeadline: Bool
    @State private var date: Date

    init(challenge: Challenge, onSave: @escaping (Date?) -> Void) {
        self.challenge = challenge
        self.onSave = onSave
        _hasDeadline = State(initialValue: challenge.endsOn != nil)
        _date = State(initialValue: challenge.endsOn ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                Toggle(isOn: $hasDeadline.animation(.snappy)) {
                    Text("Fecha límite").font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                }
                .tint(NDCColor.primary)
                if hasDeadline {
                    DatePicker("Termina el", selection: $date, in: Date()..., displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(NDCColor.primary)
                }
                Spacer()
            }
            .padding(NDCSpacing.marginMain)
            .background(NDCColor.background)
            .navigationTitle(challenge.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(hasDeadline ? date : nil)
                        dismiss()
                    }
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Alta de reto

private struct ChallengeEditorSheet: View {
    let profile: Profile
    @Environment(\.dismiss) private var dismiss
    private let repo = ChallengeRepository()

    @State private var title = ""
    @State private var description = ""
    @State private var type: ChallengeType = .comunidad
    @State private var goal = ""
    @State private var unit = "reps"
    @State private var hasEndDate = true
    @State private var endsOn = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String?

    private static let units = ["reps", "kg", "km", "burpees", "sesiones"]
    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && Double(goal) != nil && !isSaving
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    field("Nombre del reto") { TextField("Ej: 10,000 Burpees del Mes", text: $title) }
                    field("Descripción") { TextField("Objetivo colectivo, reglas…", text: $description, axis: .vertical) }

                    VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                        Text("TIPO").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                        Picker("Tipo", selection: $type) {
                            Text("Comunidad").tag(ChallengeType.comunidad)
                            Text("Individual").tag(ChallengeType.individual)
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack(spacing: NDCSpacing.stackMD) {
                        field("Meta") { TextField("10000", text: $goal).keyboardType(.numberPad) }
                        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                            Text("UNIDAD").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
                            Picker("Unidad", selection: $unit) {
                                ForEach(Self.units, id: \.self) { Text($0).tag($0) }
                            }
                            .pickerStyle(.menu)
                            .tint(NDCColor.primary)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                        }
                    }

                    Toggle(isOn: $hasEndDate) {
                        Text("Fecha límite").font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                    }
                    .tint(NDCColor.primary)
                    if hasEndDate {
                        DatePicker("Termina el", selection: $endsOn, in: Date()..., displayedComponents: .date)
                            .font(NDCFont.bodyMD)
                            .tint(NDCColor.primary)
                    }

                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
            }
            .background(NDCColor.background)
            .navigationTitle("Nuevo Reto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSaving ? "Creando…" : "Crear") { Task { await save() } }
                        .font(NDCFont.labelBold)
                        .foregroundStyle(canSave ? NDCColor.primary : NDCColor.outline)
                        .disabled(!canSave)
                }
            }
        }
        .tint(NDCColor.primary)
        .presentationDragIndicator(.visible)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG).padding(NDCSpacing.gutter)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }

    private func save() async {
        guard let goalValue = Double(goal) else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await repo.create(
                title: title.trimmingCharacters(in: .whitespaces),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                type: type,
                goalValue: goalValue,
                unit: unit,
                endsOn: hasEndDate ? endsOn : nil,
                createdBy: profile.id
            )
            Haptics.notify(.success)
            dismiss()
        } catch {
            isSaving = false
            errorMessage = "No se pudo crear el reto. Intenta de nuevo."
        }
    }
}

// MARK: - Store

@MainActor @Observable
final class CoachChallengesStore {
    struct Item: Identifiable {
        var id: UUID { challenge.id }
        let challenge: Challenge
        let participants: [Participant]

        struct Participant: Identifiable {
            let id: UUID
            let fullName: String
            let avatarURL: String?
            let joinedAt: Date
        }
    }

    private(set) var state: LoadState<[Item]> = .loading
    private let repo = ChallengeRepository()

    func load() async {
        if state.value == nil { state = .loading }
        do {
            let challenges = try await repo.activeChallenges()
            let participants = try await repo.participants(challengeIds: challenges.map(\.id))
            let profiles = try await repo.profiles(ids: Array(Set(participants.map(\.athleteId))))
            let profileById = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
            let items = challenges.map { challenge in
                Item(
                    challenge: challenge,
                    participants: participants
                        .filter { $0.challengeId == challenge.id }
                        .map { p in
                            Item.Participant(
                                id: p.athleteId,
                                fullName: profileById[p.athleteId]?.fullName ?? "Atleta",
                                avatarURL: profileById[p.athleteId]?.avatarURL,
                                joinedAt: p.joinedAt
                            )
                        }
                )
            }
            state = .loaded(items)
        } catch {
            state = .failed("No se pudieron cargar los retos.")
        }
    }

    func updateDeadline(_ challenge: Challenge, endsOn: Date?) async {
        do {
            try await repo.updateEndsOn(challengeId: challenge.id, endsOn: endsOn)
            Haptics.notify(.success)
            await load()
        } catch {
            Haptics.notify(.error)
        }
    }

    func delete(_ challenge: Challenge) async {
        do {
            try await repo.delete(challengeId: challenge.id)
            Haptics.impact(.light)
            await load()
        } catch {
            Haptics.notify(.error)
        }
    }
}

#Preview {
    NavigationStack { ChallengeManagementView(profile: .preview) }
}
