import SwiftUI

/// Validación de Marcas (coach) — diseño Stitch "Validación de Marcas".
/// Cola real: `wod_results` + `personal_records` en estado pendiente. El coach
/// valida (status = validado) o corrige (edita el valor → status = corregido)
/// cada marca, o valida todo lo listado. Se llega desde el Dashboard
/// ("Validaciones Pendientes") o desde Alertas. (ver FLOWS.md → ValidationView)
struct ValidationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = ValidationStore()
    @State private var query = ""
    @State private var correcting: ValidationStore.Item?
    @State private var confirmValidateAll = false

    private func filtered(_ items: [ValidationStore.Item]) -> [ValidationStore.Item] {
        query.isEmpty ? items : items.filter { $0.athleteName.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NDCSpacing.stackMD) {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(NDCFont.labelBold)
                            .foregroundStyle(NDCColor.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    LoadStateView(state: store.state, retry: { Task { await store.load() } }) { items in
                        if items.isEmpty {
                            ContentUnavailableView("Todo validado", systemImage: "checkmark.seal.fill",
                                                   description: Text("No quedan marcas pendientes."))
                                .padding(.top, NDCSpacing.stackLG)
                        } else {
                            ForEach(filtered(items)) { item in
                                ValidationRow(
                                    item: item,
                                    isBusy: store.busyIds.contains(item.id),
                                    onValidate: { Task { await store.validate(item) } },
                                    onCorrect: { correcting = item }
                                )
                            }
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackMD) {
                            SkeletonCard(lines: 3, height: 150)
                            SkeletonCard(lines: 3, height: 150)
                        }
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.stackSM)
                .padding(.bottom, 100)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Validar Marcas")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Buscar atleta...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(store.state.value?.count ?? 0) PENDIENTES")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(NDCColor.accent, in: .capsule)
                }
            }
            .safeAreaInset(edge: .bottom) {
                validateAllButton
            }
            .confirmationDialog(
                "¿Validar \(store.state.value?.count ?? 0) marcas pendientes?",
                isPresented: $confirmValidateAll,
                titleVisibility: .visible
            ) {
                Button("Validar Todo") { Task { await store.validateAll() } }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Quedarán como validadas por ti. Las que necesiten cambios corrígelas una a una.")
            }
            .sheet(item: $correcting) { item in
                CorrectResultSheet(item: item) {
                    store.remove(item)
                }
            }
            .task { await store.load() }
            .refreshable { await store.load() }
        }
        .tint(NDCColor.primary)
    }

    private var validateAllButton: some View {
        let isEmpty = (store.state.value?.isEmpty ?? true)
        return Button {
            Haptics.impact()
            confirmValidateAll = true
        } label: {
            Label(store.isValidatingAll ? "Validando…" : "Validar Todo", systemImage: "checkmark.circle.fill")
                .font(NDCFont.headlineSM).foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        }
        .padding(.horizontal, NDCSpacing.marginMain)
        .padding(.bottom, NDCSpacing.stackSM)
        .disabled(isEmpty || store.isValidatingAll)
        .opacity(isEmpty ? 0.5 : 1)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Fila de marca pendiente

private struct ValidationRow: View {
    let item: ValidationStore.Item
    let isBusy: Bool
    let onValidate: () -> Void
    let onCorrect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(spacing: NDCSpacing.gutter) {
                NDCAvatarView(urlString: item.avatarURL, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.athleteName).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                    Text(item.context).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
                Spacer()
                NDCChip(text: item.levelLabel)
            }
            HStack {
                Text(item.metric.uppercased()).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Spacer()
                Text(item.valueLabel).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
            }
            HStack(spacing: NDCSpacing.stackSM) {
                Button(action: onCorrect) {
                    Label("Corregir", systemImage: "pencil")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: NDCRadius.standard).stroke(NDCColor.outline.opacity(0.4), lineWidth: 1))
                }
                Button(action: onValidate) {
                    Label(isBusy ? "Validando…" : "Validar", systemImage: "checkmark")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
                }
            }
            .disabled(isBusy)
            .opacity(isBusy ? 0.6 : 1)
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.athleteName), \(item.metric) \(item.valueLabel)")
    }
}

// MARK: - Store (cola real de pendientes en las dos tablas)

@MainActor @Observable
final class ValidationStore {
    struct Item: Identifiable {
        enum Source {
            case wodResult(WodResult)
            case personalRecord(PersonalRecord)
        }

        let source: Source
        let athleteName: String
        let avatarURL: String?
        let context: String
        let metric: String
        let valueLabel: String
        /// Nivel del grupo: el elegido al registrar el WOD, o el del perfil.
        let levelLabel: String
        let sortDate: Date

        var id: UUID {
            switch source {
            case .wodResult(let r): r.id
            case .personalRecord(let pr): pr.id
            }
        }
    }

    private(set) var state: LoadState<[Item]> = .loading
    private(set) var busyIds: Set<UUID> = []
    private(set) var isValidatingAll = false
    var errorMessage: String?

    private let repo = CoachRepository()

    func load() async {
        state = .loading
        errorMessage = nil
        do {
            async let resultsTask = repo.pendingWodResults()
            async let prsTask = repo.pendingPersonalRecords()
            let (results, prs) = try await (resultsTask, prsTask)

            let athleteIds = Array(Set(results.map(\.athleteId) + prs.map(\.athleteId)))
            async let profilesTask = repo.profiles(ids: athleteIds)
            async let wodsTask = repo.wods(ids: Array(Set(results.map(\.wodId))))
            async let exercisesTask = AthleteRepository().exercises(ids: Array(Set(prs.map(\.exerciseId))))

            let profilesById = Dictionary(uniqueKeysWithValues: (try await profilesTask).map { ($0.id, $0) })
            let wodsById = Dictionary(uniqueKeysWithValues: (try await wodsTask).map { ($0.id, $0) })
            let exercisesById = Dictionary(uniqueKeysWithValues: (try await exercisesTask).map { ($0.id, $0) })

            var items: [Item] = results.map { r in
                let profile = profilesById[r.athleteId]
                return Item(
                    source: .wodResult(r),
                    athleteName: profile?.fullName ?? "Atleta",
                    avatarURL: profile?.avatarURL,
                    context: "Resultado de WOD · \(Self.dateLabel(r.createdAt))",
                    metric: "WOD: \(wodsById[r.wodId]?.title ?? "—")",
                    valueLabel: Self.valueLabel(for: r),
                    levelLabel: (r.intensity ?? profile?.level)?.displayName ?? "—",
                    sortDate: r.createdAt
                )
            }
            items += prs.map { pr in
                let profile = profilesById[pr.athleteId]
                let exercise = exercisesById[pr.exerciseId]
                return Item(
                    source: .personalRecord(pr),
                    athleteName: profile?.fullName ?? "Atleta",
                    avatarURL: profile?.avatarURL,
                    context: "Nueva marca · \(Self.dateLabel(pr.recordDate))",
                    metric: exercise?.nameEs ?? exercise?.name ?? "Ejercicio",
                    valueLabel: pr.scoreType.format(pr.value),
                    levelLabel: profile?.level.displayName ?? "—",
                    sortDate: pr.recordDate
                )
            }
            state = .loaded(items.sorted { $0.sortDate > $1.sortDate })
        } catch {
            state = .failed("No se pudieron cargar las marcas pendientes.")
        }
    }

    /// Valida una marca; la quita de la cola solo si el servidor confirmó.
    func validate(_ item: Item) async {
        guard !busyIds.contains(item.id) else { return }
        busyIds.insert(item.id)
        defer { busyIds.remove(item.id) }
        do {
            switch item.source {
            case .wodResult: try await repo.validate(wodResultIds: [item.id])
            case .personalRecord: try await repo.validate(personalRecordIds: [item.id])
            }
            Haptics.notify(.success)
            errorMessage = nil
            remove(item)
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo validar la marca de \(item.athleteName). Inténtalo de nuevo."
        }
    }

    /// Valida en lote **solo los ids listados** (no un update ciego por status,
    /// para no tocar marcas que lleguen mientras el coach revisa).
    func validateAll() async {
        guard case .loaded(let items) = state, !items.isEmpty, !isValidatingAll else { return }
        isValidatingAll = true
        defer { isValidatingAll = false }
        let wodResultIds = items.compactMap { item -> UUID? in
            switch item.source {
            case .wodResult(let r): r.id
            case .personalRecord: nil
            }
        }
        let prIds = items.compactMap { item -> UUID? in
            switch item.source {
            case .personalRecord(let pr): pr.id
            case .wodResult: nil
            }
        }
        do {
            try await repo.validate(wodResultIds: wodResultIds, personalRecordIds: prIds)
            Haptics.notify(.success)
            errorMessage = nil
            withAnimation { state = .loaded([]) }
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudieron validar todas las marcas. Revisa tu conexión e inténtalo de nuevo."
        }
    }

    func remove(_ item: Item) {
        guard case .loaded(let items) = state else { return }
        withAnimation { state = .loaded(items.filter { $0.id != item.id }) }
    }

    private static func valueLabel(for result: WodResult) -> String {
        if let time = result.formattedTime { return time }
        if let weight = result.weightUsedKg { return ScoreType.peso.format(weight) }
        if let reps = result.reps { return "\(reps) reps" }
        if let rounds = result.rounds { return "\(rounds) rondas" }
        return "—"
    }

    private static func dateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Hoy" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d MMM"
        return f.string(from: date)
    }
}

// MARK: - Corregir Marca (sheet del coach)

/// Corrige el valor de una marca pendiente. Muestra los campos de la métrica
/// que el atleta registró, prellenados; al guardar queda status = corregido y
/// validada por el coach. UI nueva (no está en `diseño/`), construida con el
/// design system NDC (CTA serio en primario oscuro, como Confirmar Resultado).
private struct CorrectResultSheet: View {
    let item: ValidationStore.Item
    /// Avisa a la cola que esta marca ya no está pendiente.
    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var minutes: String
    @State private var seconds: String
    @State private var weight: String
    @State private var reps: String
    @State private var rounds: String
    @State private var prValue: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    private let showsTime: Bool
    private let showsWeight: Bool
    private let showsReps: Bool
    private let showsRounds: Bool

    init(item: ValidationStore.Item, onSaved: @escaping () -> Void) {
        self.item = item
        self.onSaved = onSaved
        switch item.source {
        case .wodResult(let r):
            // Se corrigen las métricas que el atleta registró; si no registró
            // ninguna, se ofrecen tiempo y peso.
            let hasAny = r.timeSeconds != nil || r.weightUsedKg != nil || r.reps != nil || r.rounds != nil
            showsTime = r.timeSeconds != nil || !hasAny
            showsWeight = r.weightUsedKg != nil || !hasAny
            showsReps = r.reps != nil
            showsRounds = r.rounds != nil
            _minutes = State(initialValue: r.timeSeconds.map { String($0 / 60) } ?? "")
            _seconds = State(initialValue: r.timeSeconds.map { String($0 % 60) } ?? "")
            _weight = State(initialValue: r.weightUsedKg.map { Self.trimmed($0) } ?? "")
            _reps = State(initialValue: r.reps.map(String.init) ?? "")
            _rounds = State(initialValue: r.rounds.map(String.init) ?? "")
            _prValue = State(initialValue: "")
        case .personalRecord(let pr):
            showsTime = false; showsWeight = false; showsReps = false; showsRounds = false
            _minutes = State(initialValue: ""); _seconds = State(initialValue: "")
            _weight = State(initialValue: ""); _reps = State(initialValue: ""); _rounds = State(initialValue: "")
            _prValue = State(initialValue: Self.trimmed(pr.value))
        }
    }

    private var canSave: Bool {
        guard !isSaving else { return false }
        switch item.source {
        case .personalRecord:
            return Double(prValue.replacingOccurrences(of: ",", with: ".")) != nil
        case .wodResult:
            let hasTime = showsTime && (Int(minutes) ?? 0) + (Int(seconds) ?? 0) > 0
            let hasWeight = showsWeight && Double(weight.replacingOccurrences(of: ",", with: ".")) != nil
            let hasReps = showsReps && Int(reps) != nil
            let hasRounds = showsRounds && Int(rounds) != nil
            return hasTime || hasWeight || hasReps || hasRounds
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    athleteHeader
                    currentValueCard
                    fieldsSection
                    disclaimer
                    if let errorMessage {
                        Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                    }
                }
                .padding(NDCSpacing.marginMain)
                .padding(.bottom, 80)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(NDCColor.surface)
            .navigationTitle("Corregir Marca")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await save() }
                } label: {
                    Label(isSaving ? "Guardando…" : "Guardar Corrección", systemImage: "checkmark.circle.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
                .disabled(!canSave)
                .opacity(canSave || isSaving ? 1 : 0.5)
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.bottom, NDCSpacing.stackSM)
                .background(.ultraThinMaterial)
            }
        }
        .tint(NDCColor.primary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var athleteHeader: some View {
        HStack(spacing: NDCSpacing.gutter) {
            NDCAvatarView(urlString: item.avatarURL, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.athleteName).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                Text(item.context).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            NDCChip(text: item.levelLabel)
        }
    }

    private var currentValueCard: some View {
        HStack {
            Text(item.metric.uppercased()).font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8))
            Spacer()
            VStack(alignment: .trailing, spacing: 0) {
                Text("REGISTRADO").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.6))
                Text(item.valueLabel).font(NDCFont.headlineMD).foregroundStyle(NDCColor.accent)
            }
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Valor registrado: \(item.valueLabel)")
    }

    @ViewBuilder
    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            Text("VALOR CORREGIDO").font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            switch item.source {
            case .personalRecord(let pr):
                numberField(text: $prValue, placeholder: "0.0", unit: Self.unitLabel(pr.scoreType), decimal: true)
            case .wodResult:
                if showsTime {
                    HStack(spacing: NDCSpacing.gutter) {
                        labeledField("Minutos") { numberField(text: $minutes, placeholder: "00", unit: nil, decimal: false) }
                        labeledField("Segundos") { numberField(text: $seconds, placeholder: "00", unit: nil, decimal: false) }
                    }
                }
                if showsWeight {
                    labeledField("Peso") { numberField(text: $weight, placeholder: "0.0", unit: "KG", decimal: true) }
                }
                if showsReps {
                    labeledField("Repeticiones") { numberField(text: $reps, placeholder: "0", unit: "REPS", decimal: false) }
                }
                if showsRounds {
                    labeledField("Rondas") { numberField(text: $rounds, placeholder: "0", unit: "RONDAS", decimal: false) }
                }
            }
        }
    }

    private func labeledField<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func numberField(text: Binding<String>, placeholder: String, unit: String?, decimal: Bool) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .keyboardType(decimal ? .decimalPad : .numberPad)
                .font(NDCFont.bodyLG)
            if let unit {
                Text(unit).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            }
        }
        .padding(.horizontal, NDCSpacing.gutter)
        .frame(height: 48)
        .background(NDCColor.surfaceStrong, in: .rect(cornerRadius: NDCRadius.standard))
    }

    private var disclaimer: some View {
        HStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "info.circle.fill").foregroundStyle(NDCColor.secondary)
            Text("Al guardar, la marca queda como CORREGIDA y validada por ti. El atleta verá el valor corregido.")
                .font(NDCFont.labelSM).foregroundStyle(NDCColor.onSurfaceVariant)
        }
        .padding(NDCSpacing.stackMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.standard))
    }

    private func save() async {
        guard canSave else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            switch item.source {
            case .personalRecord(let pr):
                guard let value = Double(prValue.replacingOccurrences(of: ",", with: ".")) else { return }
                try await CoachRepository().correctPersonalRecord(id: pr.id, value: value)
            case .wodResult(let r):
                let mins = Int(minutes) ?? 0
                let secs = Int(seconds) ?? 0
                let time: Int? = showsTime && (mins + secs) > 0 ? mins * 60 + secs : nil
                try await CoachRepository().correctWodResult(
                    id: r.id,
                    timeSeconds: time,
                    reps: showsReps ? Int(reps) : nil,
                    rounds: showsRounds ? Int(rounds) : nil,
                    weightUsedKg: showsWeight ? Double(weight.replacingOccurrences(of: ",", with: ".")) : nil
                )
            }
            Haptics.notify(.success)
            onSaved()
            dismiss()
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la corrección. Revisa tu conexión e inténtalo de nuevo."
        }
    }

    private static func unitLabel(_ scoreType: ScoreType) -> String {
        switch scoreType {
        case .peso: "KG"
        case .tiempo: "SEG"
        case .reps: "REPS"
        case .rondas: "RONDAS"
        case .distancia: "KM"
        case .calorias: "CAL"
        }
    }

    private static func trimmed(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }
}

#Preview {
    ValidationView()
}
