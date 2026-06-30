import SwiftUI

/// Validación de Marcas (coach) — diseño Stitch "Validación de Marcas".
/// Lista de resultados/PRs en estado pendiente; el coach valida o corrige cada
/// uno, o valida todos. Se llega desde el Dashboard ("Validaciones Pendientes")
/// o desde Alertas ("Validar"). (ver FLOWS.md → ValidationView)
///
/// TODO(datos): hoy usa `ValidationData.sample`. Conectar a Supabase:
/// wod_results + personal_records (status = pendiente). Validar → status validado.
struct ValidationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pending = ValidationData.sample
    @State private var query = ""

    private var filtered: [ValidationData.Item] {
        query.isEmpty ? pending : pending.filter { $0.athlete.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: NDCSpacing.stackMD) {
                    ForEach(filtered) { item in
                        ValidationRow(item: item,
                                      onValidate: { remove(item) },
                                      onCorrect: { /* TODO: → CorrectResultSheet */ })
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
                    Text("\(pending.count) PENDIENTES")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(NDCColor.accent, in: .capsule)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    Haptics.notify(.success)
                    withAnimation { pending.removeAll() }
                } label: {
                    Label("Validar Todo", systemImage: "checkmark.circle.fill")
                        .font(NDCFont.headlineSM).foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
                }
                .padding(.horizontal, NDCSpacing.marginMain)
                .padding(.bottom, NDCSpacing.stackSM)
                .disabled(pending.isEmpty)
                .opacity(pending.isEmpty ? 0.5 : 1)
                .background(.ultraThinMaterial)
            }
            .overlay {
                if pending.isEmpty {
                    ContentUnavailableView("Todo validado", systemImage: "checkmark.seal.fill",
                                           description: Text("No quedan marcas pendientes."))
                }
            }
        }
        .tint(NDCColor.primary)
    }

    private func remove(_ item: ValidationData.Item) {
        Haptics.notify(.success)
        withAnimation { pending.removeAll { $0.id == item.id } }
    }
}

private struct ValidationRow: View {
    let item: ValidationData.Item
    let onValidate: () -> Void
    let onCorrect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: NDCSpacing.stackMD) {
            HStack(spacing: NDCSpacing.gutter) {
                NDCAvatarView(urlString: nil, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.athlete).font(NDCFont.labelBold).foregroundStyle(NDCColor.onSurface)
                    Text(item.context).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                }
                Spacer()
                NDCChip(text: item.rxLevel)
            }
            HStack {
                Text(item.metric.uppercased()).font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Spacer()
                Text(item.value).font(NDCFont.headlineMD).foregroundStyle(NDCColor.primary)
            }
            HStack(spacing: NDCSpacing.stackSM) {
                Button(action: onCorrect) {
                    Label("Corregir", systemImage: "pencil")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .overlay(RoundedRectangle(cornerRadius: NDCRadius.standard).stroke(NDCColor.outline.opacity(0.4), lineWidth: 1))
                }
                Button(action: onValidate) {
                    Label("Validar", systemImage: "checkmark")
                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.standard))
                }
            }
        }
        .padding(NDCSpacing.stackLG)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(item.athlete), \(item.metric) \(item.value)")
    }
}

private enum ValidationData {
    struct Item: Identifiable {
        let id = UUID()
        let athlete, context, metric, value, rxLevel: String
    }
    static let sample: [Item] = [
        Item(athlete: "Mateo Jiménez", context: "Clase 8:00 am", metric: "Metcon \"The Executive\"", value: "08:42", rxLevel: "RX"),
        Item(athlete: "Valeria Ruiz", context: "Clase 8:00 am", metric: "Back Squat 1RM", value: "95 kg", rxLevel: "RX"),
        Item(athlete: "Santi Castro", context: "Clase 8:00 am", metric: "Metcon \"The Executive\"", value: "10:04", rxLevel: "Escalado")
    ]
}

#Preview {
    ValidationView()
}
