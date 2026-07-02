import SwiftUI

/// Horario de Clases (coach) — pantalla nueva (no está en `diseño/`), construida
/// con el design system NDC (selector de días como Gestión de WODs, tarjetas
/// sobre `surface`, FAB amarillo).
///
/// El coach programa las clases del box (`class_sessions`: fecha + hora únicas,
/// título y capacidad). Sobre estas sesiones operan el Control de Asistencia y
/// el QR — programar aquí primero deja el resto del flujo apuntando a la clase
/// correcta. Eliminar una clase borra también su asistencia (se confirma antes).
struct ClassScheduleView: View {
    @State private var store = ClassScheduleStore()
    @State private var selectedDayIndex = 0
    @State private var showAddClass = false
    @State private var sessionPendingDelete: ClassSession?

    /// Hoy + 13 días: suficiente para armar la semana en curso y la siguiente.
    private let days: [Date] = (0..<14).map {
        Calendar.current.date(byAdding: .day, value: $0, to: Calendar.current.startOfDay(for: Date()))!
    }
    private var selectedDay: Date { days[selectedDayIndex] }

    private static let weekdayFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEE"; return f
    }()
    private static let dayLongFmt: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "es_ES"); f.dateFormat = "EEEE d 'de' MMMM"; return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                daySelector
                Text(Self.dayLongFmt.string(from: selectedDay).capitalized)
                    .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                if let errorMessage = store.errorMessage {
                    Text(errorMessage).font(NDCFont.labelBold).foregroundStyle(NDCColor.error)
                }
                LoadStateView(state: store.state, retry: { Task { await store.load(day: selectedDay) } }) { sessions in
                    if sessions.isEmpty {
                        ContentUnavailableView(
                            "Sin clases programadas",
                            systemImage: "calendar.badge.plus",
                            description: Text("Añade la primera clase de este día con el botón +.")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        ForEach(sessions) { session in
                            SessionRow(session: session) {
                                sessionPendingDelete = session
                            }
                        }
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackMD) {
                        SkeletonCard(lines: 1, height: 72)
                        SkeletonCard(lines: 1, height: 72)
                        SkeletonCard(lines: 1, height: 72)
                    }
                }
            }
            .padding(.horizontal, NDCSpacing.marginMain)
            .padding(.top, NDCSpacing.stackSM)
            .padding(.bottom, 96)
        }
        .background(NDCColor.background)
        .scrollIndicators(.hidden)
        .navigationTitle("Horario de Clases")
        .navigationBarTitleDisplayMode(.large)
        .overlay(alignment: .bottomTrailing) { addFAB }
        .sheet(isPresented: $showAddClass) {
            AddClassSheet(day: selectedDay) { startTime, title, capacity in
                await store.add(day: selectedDay, startTime: startTime, title: title, capacity: capacity)
            }
        }
        .confirmationDialog(
            "¿Eliminar la clase de las \(sessionPendingDelete?.formattedStartTime ?? "")?",
            isPresented: Binding(get: { sessionPendingDelete != nil },
                                 set: { if !$0 { sessionPendingDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("Eliminar clase", role: .destructive) {
                if let session = sessionPendingDelete {
                    Task { await store.delete(session, day: selectedDay) }
                }
                sessionPendingDelete = nil
            }
            Button("Cancelar", role: .cancel) { sessionPendingDelete = nil }
        } message: {
            Text("También se borrará la asistencia registrada de esa clase. Esta acción no se puede deshacer.")
        }
        .task { await store.load(day: selectedDay) }
        .refreshable { await store.load(day: selectedDay) }
        .onChange(of: selectedDayIndex) {
            Task { await store.load(day: selectedDay) }
        }
    }

    // MARK: - Selector de días (hoy + 13)

    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NDCSpacing.stackSM) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    Button {
                        Haptics.selection()
                        selectedDayIndex = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(Self.weekdayFmt.string(from: day).uppercased()).font(NDCFont.labelSM)
                            Text(day.formatted(.dateTime.day())).font(NDCFont.headlineSM)
                        }
                        .foregroundStyle(selectedDayIndex == index ? .white : NDCColor.primary)
                        .frame(width: 52, height: 64)
                        .background(selectedDayIndex == index ? NDCColor.primary : NDCColor.surface,
                                    in: .rect(cornerRadius: NDCRadius.large))
                    }
                    .accessibilityLabel(Self.dayLongFmt.string(from: day))
                    .accessibilityAddTraits(selectedDayIndex == index ? .isSelected : [])
                }
            }
        }
    }

    private var addFAB: some View {
        Button {
            Haptics.impact()
            showAddClass = true
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
        .accessibilityLabel("Añadir clase")
    }
}

// MARK: - Fila de clase programada

private struct SessionRow: View {
    let session: ClassSession
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: NDCSpacing.gutter) {
            Text(session.formattedStartTime)
                .font(NDCFont.headlineSM)
                .foregroundStyle(NDCColor.onAccent)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title ?? "Clase")
                    .font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                Label("\(session.capacity) cupos", systemImage: "person.3.fill")
                    .font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
            }
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash").foregroundStyle(NDCColor.error)
            }
            .accessibilityLabel("Eliminar clase de las \(session.formattedStartTime)")
        }
        .padding(NDCSpacing.gutter)
        .background(NDCColor.background, in: .rect(cornerRadius: NDCRadius.large))
        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.outline.opacity(0.2), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Sheet para añadir clase

private struct AddClassSheet: View {
    let day: Date
    /// Guarda en el store; devuelve al cerrar sin error.
    let onAdd: (_ startTime: String, _ title: String?, _ capacity: Int) async -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var time = Self.defaultTime
    @State private var title = ""
    @State private var capacity = "50"
    @State private var isSaving = false

    /// Próxima hora en punto (las clases suelen empezar en punto).
    private static var defaultTime: Date {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: Date())
        return cal.date(bySettingHour: min(hour + 1, 22), minute: 0, second: 0, of: Date()) ?? Date()
    }

    private var dayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEEE d 'de' MMMM"
        return f.string(from: day).capitalized
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                    Label(dayLabel, systemImage: "calendar")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                    field("Hora de Inicio") {
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden().tint(NDCColor.primary)
                    }
                    field("Nombre de la Clase (opcional)") {
                        TextField("Ej: WOD Class, Open Box...", text: $title)
                    }
                    field("Capacidad") {
                        HStack {
                            TextField("50", text: $capacity).keyboardType(.numberPad)
                            Text("CUPOS").foregroundStyle(NDCColor.outline)
                        }
                    }
                }
                .padding(NDCSpacing.marginMain)
            }
            .background(NDCColor.background)
            .navigationTitle("Nueva Clase")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task {
                        isSaving = true
                        let f = DateFormatter()
                        f.locale = Locale(identifier: "en_US_POSIX")
                        f.dateFormat = "HH:mm"
                        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
                        let ok = await onAdd(
                            f.string(from: time),
                            trimmedTitle.isEmpty ? nil : trimmedTitle,
                            Int(capacity) ?? 50
                        )
                        isSaving = false
                        if ok { dismiss() }
                    }
                } label: {
                    Label(isSaving ? "Guardando…" : "Añadir Clase", systemImage: "checkmark.circle.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
                .disabled(isSaving)
                .padding(.horizontal, NDCSpacing.marginMain).padding(.bottom, NDCSpacing.stackSM)
                .background(.ultraThinMaterial)
            }
        }
        .tint(NDCColor.primary)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func field<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
            Text(title.uppercased()).font(NDCFont.labelBold).foregroundStyle(NDCColor.outline)
            content()
                .font(NDCFont.bodyLG).padding(NDCSpacing.gutter)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        }
    }
}

// MARK: - Store (clases del día seleccionado)

@MainActor @Observable
final class ClassScheduleStore {
    private(set) var state: LoadState<[ClassSession]> = .loading
    var errorMessage: String?
    private let repo = CoachRepository()

    func load(day: Date) async {
        state = .loading
        errorMessage = nil
        do {
            state = .loaded(try await repo.sessions(on: day))
        } catch {
            state = .failed("No se pudo cargar el horario de este día.")
        }
    }

    /// Devuelve true si se guardó (el sheet se cierra solo en ese caso).
    func add(day: Date, startTime: String, title: String?, capacity: Int) async -> Bool {
        errorMessage = nil
        do {
            _ = try await repo.scheduleSession(date: day, startTime: startTime,
                                               title: title, capacity: capacity)
            Haptics.notify(.success)
            await load(day: day)
            return true
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo guardar la clase. Revisa tu conexión e inténtalo de nuevo."
            return false
        }
    }

    func delete(_ session: ClassSession, day: Date) async {
        errorMessage = nil
        do {
            try await repo.deleteSession(id: session.id)
            Haptics.notify(.success)
            await load(day: day)
        } catch {
            Haptics.notify(.error)
            errorMessage = "No se pudo eliminar la clase. Inténtalo de nuevo."
        }
    }
}

#Preview {
    NavigationStack { ClassScheduleView() }
}
