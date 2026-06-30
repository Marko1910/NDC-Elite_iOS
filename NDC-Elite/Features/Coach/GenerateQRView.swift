import SwiftUI
import CoreImage.CIFilterBuiltins

/// Generar QR de Asistencia (coach) — diseño Stitch "Generar QR de Asistencia".
/// El coach muestra este QR en el box; los atletas lo escanean con su app
/// (AttendanceScannerView) para registrar asistencia. El QR codifica el id de la
/// clase actual. (ver FLOWS.md → AttendanceView / QrScannerView)
///
/// TODO(datos): el payload debe ser el id real de la `class_sessions` actual,
/// firmado/temporal para evitar reusos. Hoy usa un payload de muestra.
struct GenerateQRView: View {
    @Environment(\.dismiss) private var dismiss
    let classLabel: String
    let payload: String

    init(classLabel: String = "07:00 AM - El Titán",
         payload: String = "ndc-attendance://session/demo-\(UUID().uuidString.prefix(8))") {
        self.classLabel = classLabel
        self.payload = payload
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: NDCSpacing.stackLG) {
                classBanner
                qrCard
                Spacer()
                actions
            }
            .padding(NDCSpacing.marginMain)
            .background(NDCColor.background)
            .navigationTitle("Generar QR de Asistencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                        .accessibilityLabel("Volver")
                }
            }
        }
        .tint(NDCColor.primary)
    }

    private var classBanner: some View {
        HStack(spacing: NDCSpacing.gutter) {
            Image(systemName: "timer")
                .font(.system(size: 22)).foregroundStyle(NDCColor.onAccent)
                .frame(width: 44, height: 44)
                .background(NDCColor.accent, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("CLASE ACTUAL").font(NDCFont.labelSM).foregroundStyle(NDCColor.outline)
                Text(classLabel).font(NDCFont.headlineSM).foregroundStyle(NDCColor.primary)
            }
            Spacer()
        }
        .padding(NDCSpacing.gutter)
        .frame(maxWidth: .infinity)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private var qrCard: some View {
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
                    .accessibilityLabel("Código QR de asistencia para \(classLabel)")
            }
            Label("Código activo y listo", systemImage: "checkmark.seal.fill")
                .font(NDCFont.labelBold).foregroundStyle(.green)
        }
        .padding(NDCSpacing.stackLG)
        .frame(maxWidth: .infinity)
        .background(NDCColor.surface, in: .rect(cornerRadius: NDCRadius.large))
    }

    private var actions: some View {
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

#Preview {
    GenerateQRView()
}
