import SwiftUI

/// Ejercicios de un WOD (bloques + prescripciones) en una hoja.
/// La usan el atleta (Historial de WODs) y el coach (Gestión de WODs y
/// resumen semanal) para ver qué se entrenó/entrenará ese día sin abrir el editor.
struct WodExercisesSheet: View {
    let wodId: UUID
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var state: LoadState<[BlockVM]> = .loading
    private let repo = WodRepository()

    struct BlockVM: Identifiable {
        let id: UUID
        let title: String
        let exercises: [String]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LoadStateView(state: state, retry: { Task { await load() } }) { blocks in
                    if blocks.allSatisfy(\.exercises.isEmpty) {
                        ContentUnavailableView(
                            "Sin ejercicios",
                            systemImage: "list.bullet.rectangle",
                            description: Text("Este WOD no tiene ejercicios registrados (ej. sesión de running).")
                        )
                        .padding(.top, NDCSpacing.stackLG)
                    } else {
                        VStack(alignment: .leading, spacing: NDCSpacing.stackLG) {
                            ForEach(blocks) { block in
                                VStack(alignment: .leading, spacing: NDCSpacing.stackSM) {
                                    Text(block.title.uppercased())
                                        .font(NDCFont.labelBold).foregroundStyle(NDCColor.outline).tracking(1)
                                    if block.exercises.isEmpty {
                                        Text("—").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                                    } else {
                                        ForEach(Array(block.exercises.enumerated()), id: \.offset) { _, prescription in
                                            HStack(alignment: .top, spacing: NDCSpacing.stackSM) {
                                                Circle().fill(NDCColor.accent).frame(width: 8, height: 8)
                                                    .padding(.top, 6)
                                                Text(prescription)
                                                    .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurface)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Spacer(minLength: 0)
                                            }
                                        }
                                    }
                                }
                                .padding(NDCSpacing.gutter)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
                            }
                        }
                        .padding(NDCSpacing.marginMain)
                    }
                } skeleton: {
                    VStack(spacing: NDCSpacing.stackMD) {
                        SkeletonCard(lines: 3, height: 110)
                        SkeletonCard(lines: 3, height: 110)
                    }
                    .padding(NDCSpacing.marginMain)
                }
            }
            .background(NDCColor.background)
            .scrollIndicators(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }.foregroundStyle(NDCColor.primary)
                }
            }
            .task { await load() }
        }
        .tint(NDCColor.primary)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func load() async {
        do {
            let blocks = try await repo.fetchBlocks(wodId: wodId)
            let exercises = try await repo.fetchBlockExercises(blockIds: blocks.map(\.id))
            state = .loaded(blocks.map { block in
                BlockVM(
                    id: block.id,
                    title: block.title ?? block.blockType.displayName,
                    exercises: exercises.filter { $0.blockId == block.id }.map(\.prescription)
                )
            })
        } catch {
            state = .failed("No se pudieron cargar los ejercicios.")
        }
    }
}

#Preview {
    Color.gray.sheet(isPresented: .constant(true)) {
        WodExercisesSheet(wodId: UUID(), title: "Motor de Julio")
    }
}
