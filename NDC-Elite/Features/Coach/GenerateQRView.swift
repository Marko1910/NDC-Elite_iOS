import SwiftUI
import CoreImage.CIFilterBuiltins

/// Generar QR de Asistencia (coach) — diseño Stitch "Generar QR de Asistencia".
/// El coach muestra este QR en el box; los atletas lo escanean con su app
/// (AttendanceScannerView) para registrar asistencia.
///
/// El QR codifica el id real de la `class_sessions` de hoy a la hora actual
/// (se crea si no existe; única por fecha+hora).
struct GenerateQRView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = GenerateQRStore()
    /// Sesión ya resuelta por la pantalla anterior (Control de Asistencia);
    /// garantiza que el QR y el toggle manual escriben en la MISMA clase.
    /// Si es nil, se busca/crea la clase de hoy a la hora actual.
    private let presetSession: ClassSession?

    init(presetSession: ClassSession? = nil) {
        self.presetSession = presetSession
    }

    /// Prefijo compartido con `AttendanceScannerView` para validar el escaneo.
    static let payloadPrefix = "ndc-attendance://session/"

    var body: some View {
        NavigationStack {
            LoadStateView(state: store.state, retry: { Task { await store.load() } }) { session in
                let payload = Self.payloadPrefix + session.id.uuidString
                VStack(spacing: NDCSpacing.stackLG) {
                    classBanner(session)
                    qrCard(payload: payload, session: session)
                    Spacer()
                    actions(payload: payload)
                }
                .padding(NDCSpacing.marginMain)
            } skeleton: {
                VStack(spacing: NDCSpacing.stackLG) {
                    SkeletonCard(lines: 1, height: 76)
                    SkeletonBlock(height: 300, cornerRadius: NDCRadius.large)
                    Spacer()
                }
                .padding(NDCSpacing.marginMain)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(NDCColor.background)
            .navigationTitle("Generar QR de Asistencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Volver")
                }
            }
            .task {
                if let presetSession {
                    store.use(presetSession)
                } else {
                    await store.load()
                }
            }
        }
        .tint(NDCColor.primary)
    }

    private func classBanner(_ session: ClassSession) -> some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: "timer")
                .font(.system(size: 22)).foregroundStyle(NDCColor.onAccent)
                .frame(width: 44, height: 44)
                .background(NDCColor.accent, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("CLASE ACTUAL").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Text("\(session.formattedStartTime) · \(session.title ?? "Clase de hoy")")
                    .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            }
            Spacer()
        }
        .padding(NDCSpacing.gutter)
        .frame(maxWidth: .infinity)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func qrCard(payload: String, session: ClassSession) -> some View {
        VStack(spacing: NDCSpacing.stackLG) {
            Text("Los atletas deben escanear este código desde su app NDC para registrar su asistencia automáticamente.")
                .font(NDCFont.bodyMD).foregroundStyle(NDCColor.onSurfaceVariant)
                .multilineTextAlignment(.center)
            if let qr = Self.makeQR(from: payload) {
                Image(uiImage: qr)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(NDCSpacing.gutter)
                    .background(.white, in: .rect(cornerRadius: NDCRadius.large))
                    .accessibilityLabel("Código QR de asistencia para la clase de las \(session.formattedStartTime)")
            }
            Label("Código activo y listo", systemImage: "checkmark.seal.fill")
                .font(NDCFont.labelBold).foregroundStyle(.green)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private func actions(payload: String) -> some View {
        VStack(spacing: NDCSpacing.stackMD) {
            Button {
                Haptics.impact()
                // TODO: imprimir (UIPrintInteractionController)
            } label: {
                Label("Imprimir Código QR", systemImage: "printer.fill")
                    .font(NDCFont.headlineSM).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(NDCColor.primary, in: .rect(cornerRadius: NDCRadius.large))
            }
            if let qr = Self.makeQR(from: payload) {
                ShareLink(item: Image(uiImage: qr), preview: SharePreview("QR de Asistencia NDC", image: Image(uiImage: qr))) {
                    Label("Compartir Digitalmente", systemImage: "square.and.arrow.up")
                        .font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .overlay(RoundedRectangle(cornerRadius: NDCRadius.large).stroke(NDCColor.primary, lineWidth: 1))
                }
                .simultaneousGesture(TapGesture().onEnded { Haptics.impact(.light) })
            }
        }
    }

    /// Genera la imagen QR del payload con CoreImage.
    static func makeQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cg = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

// MARK: - Store (sesión de clase real de hoy)

@MainActor @Observable
final class GenerateQRStore {
    private(set) var state: LoadState<ClassSession> = .loading
    private let repo = CoachRepository()

    /// Usa una sesión ya resuelta (sin ir a la red).
    func use(_ session: ClassSession) {
        state = .loaded(session)
    }

    func load() async {
        state = .loading
        do {
            // Sesión de hoy en la hora en curso (18:37 → clase de las 18:00).
            let hour = Calendar.current.component(.hour, from: Date())
            let session = try await repo.findOrCreateSession(
                date: Date(),
                startTime: String(format: "%02d:00", hour)
            )
            state = .loaded(session)
        } catch {
            state = .failed("No se pudo preparar la clase de hoy. Revisa tu conexión.")
        }
    }
}

#Preview {
    GenerateQRView()
}
