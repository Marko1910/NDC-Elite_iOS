import SwiftUI

/// Tab 2 · WODs del coach — diseño Stitch "Gestión de WODs".
/// Selector de semana (real, semana actual) · resumen semanal · lista de WODs
/// por día con estado (publicado/borrador), tipo y acciones (editar/eliminar
/// reales) · FAB para crear WOD o sesión de running. (ver FLOWS.md → WodManagementView)
struct WodManagementView: View {
    let profile: Profile
    @State private var store = WodManagementStore()
    @State private var selectedDay = Calendar.current.component(.weekday, from: Date()) == 1 ? 6 : Calendar.current.component(.weekday, from: Date()) - 2
    @State private var showWodEditor = false
    @State private var showRunningEditor = false
    @State private var editingWod: Wod?
    @State private var wodPendingDelete: Wod?

    private let weekStart = CoachRepository.startOfWeek(containing: Date())
    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEE"; return f
    }()
    private static let weekdayLongFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE"; return f
    }()

    private var weekDays: [Date] {
        (0..<7).map { Calendar.current.date(byAdding: .day, value: $0, to: weekStart)! }
    }
    private var selectedDate: Date { weekDays[selectedDay] }

    private func wodsForSelectedDay(_ all: [Wod]) -> [Wod] {
        all.filter { Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    weekSelector
                    LoadStateView(state: store.state, retry: { Task { await load() } }) { all in
                        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                            weeklySummary(count: all.count)
                            dayHeader(count: wodsForSelectedDay(all).count)
                            let dayWods = wodsForSelectedDay(all)
                            if dayWods.isEmpty {
                                Text("Sin WODs programados este día.")
                                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                            } else {
                                ForEach(dayWods) { wod in
                                    WodManagementRow(
                                        wod: wod,
                                        onEdit: { editingWod = wod; showWodEditor = true },
                                        onDelete: { wodPendingDelete = wod }
                                    )
                                }
                            }
                        }
                    } skeleton: {
                        VStack(spacing: NDCSpacing.stackMD) {
                            SkeletonCard(lines: 1, height: 90)
                            SkeletonCard(lines: 3, height: 100)
                        }
                    }
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.top, NDCSpacing.gutter)
                .padding(.bottom, 96)
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle("Gestión de WODs")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottomTrailing) { createFAB }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ExerciseLibraryManagementView(profile: profile)
                    } label: {
                        Image(systemName: "books.vertical.fill")
                    }
                    .accessibilityLabel("Biblioteca Técnica")
                }
            }
            .navigationDestination(isPresented: $showWodEditor) {
                WodEditorView(profile: profile, existingWod: editingWod)
            }
            .sheet(isPresented: $showRunningEditor) { RunningEditorView() }
            .confirmationDialog(
                "¿Eliminar \(wodPendingDelete?.title ?? "este WOD")?",
                isPresented: Binding(get: { wodPendingDelete != nil }, set: { if !$0 { wodPendingDelete = nil } }),
                titleVisibility: .visible
            ) {
                Button("Eliminar", role: .destructive) {
                    if let wod = wodPendingDelete { Task { try? await store.delete(wod) } }
                    wodPendingDelete = nil
                }
                Button("Cancelar", role: .cancel) { wodPendingDelete = nil }
            }
            .task { await load() }
            .refreshable { await load() }
            .onChange(of: showWodEditor) { _, isShowing in
                if !isShowing { editingWod = nil; Task { await load() } }
            }
        }
        .tint(NDCColor.primary)
    }

    private func load() async {
        let weekEnd = Calendar.current.date(byAdding: .day, value: 6, to: weekStart)!
        await store.load(weekStart: weekStart, weekEnd: weekEnd)
    }

    private var weekSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                    Button {
                        Haptics.selection()
                        selectedDay = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(Self.weekdayFmt.string(from: day).uppercased()).font(NDCFont.labelSM)
                            Text(day.formatted(.dateTime.day())).font(NDCFont.headlineSM)
                        }
                        .foregroundStyle(selectedDay == index ? .white : NDCColor.primary)
                        .frame(width: 52, height: 64)
                        .background(selectedDay == index ? NDCColor.primary : NDCColor.surface,
                                    in: .rect(cornerRadius: NDCRadius.large))
                    }
                    .accessibilityLabel("\(Self.weekdayLongFmt.string(from: day)) \(day.formatted(.dateTime.day()))")
                    .accessibilityAddTraits(selectedDay == index ? .isSelected : [])
                }
            }
        }
    }

    private func weeklySummary(count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("RESUMEN SEMANAL").font(NDCFont.labelSM).foregroundStyle(.white.opacity(0.8)).tracking(1)
                Text("\(count) WODs").font(NDCFont.headlineMD).foregroundStyle(.white)
                Text("Programados para esta semana").font(NDCFont.labelSM).foregroundStyle(NDCColor.primaryFixed)
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 28)).foregroundStyle(NDCColor.accent)
                .frame(width: 52, height: 52)
                .background(.white.opacity(0.12), in: .rect(cornerRadius: NDCRadius.standard))
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func dayHeader(count: Int) -> some View {
        HStack {
            Text("WODs del \(Self.weekdayLongFmt.string(from: selectedDate).capitalized)")
                .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            Spacer()
            Text("\(count) sesiones").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
        }
    }

    private var createFAB: some View {
        Menu {
            Button { Haptics.impact(); editingWod = nil; showWodEditor = true } label: {
                Label("Nuevo WOD", systemImage: "plus.square.on.square")
            }
            Button { Haptics.impact(); showRunningEditor = true } label: {
                Label("Nueva Sesión de Running", systemImage: "figure.run")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(NDCColor.primary)
                .frame(width: 56, height: 56)
                .background(NDCColor.accent, in: .circle)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .padding(.trailing, NDCSpacing.marginMain)
        .padding(.bottom, NDCSpacing.stackLG)
        .accessibilityLabel("Crear WOD o sesión")
    }
}

// MARK: - Store (WODs reales de la semana)

@MainActor @Observable
final class WodManagementStore {
    private(set) var state: LoadState<[Wod]> = .loading
    private let repo = WodRepository()

    func load(weekStart: Date, weekEnd: Date) async {
        state = .loading
        do {
            state = .loaded(try await repo.fetchWods(from: weekStart, to: weekEnd))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func delete(_ wod: Wod) async throws {
        try await repo.delete(wodId: wod.id)
        if case .loaded(var list) = state {
            list.removeAll { $0.id == wod.id }
            state = .loaded(list)
        }
    }
}

// MARK: - Fila de WOD (gestión)

private struct WodManagementRow: View {
    let wod: Wod
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var metric: String {
        if wod.wodType == .running, let km = wod.distanceKm {
            return String(format: "%.1fkm", km)
        }
        if let cap = wod.timeCapMinutes { return "\(cap)' Cap" }
        return "—"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            HStack {
                Text(wod.status.displayName.uppercased())
                    .font(NDCFont.labelSM)
                    .foregroundStyle(wod.status == .publicado ? .green : NDCColor.outline)
                Spacer()
                HStack(spacing: NDCSpacing.gutter) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil").foregroundStyle(NDCColor.primary)
                    }
                    .accessibilityLabel("Editar \(wod.title)")
                    Button(action: onDelete) {
                        Image(systemName: "trash").foregroundStyle(NDCColor.error)
                    }
                    .accessibilityLabel("Eliminar \(wod.title)")
                }
            }
            Text(wod.title).font(NDCFont.headlineSM).foregroundStyle(NDCColor.onSurface)
            HStack(spacing: NDCSpacing.stackSM) {
                Label(metric, systemImage: wod.wodType == .running ? "figure.run" : "timer")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.onSurfaceVariant)
                NDCChip(text: wod.wodType.displayName)
            }
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    WodManagementView(profile: .preview)
}
