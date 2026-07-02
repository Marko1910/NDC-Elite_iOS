import SwiftUI

/// Escáner QR de asistencia del atleta — pantalla nueva (no existe en Stitch).
/// El atleta, al llegar al gym, escanea el QR que muestra el coach y su
/// asistencia se registra. Reemplaza la campana en el perfil del atleta.
///
/// Flujo: pide permiso de cámara → escanea el QR del coach (id de la
/// `class_sessions` actual) → inserta en `attendance` (check_in_method = 'qr').
/// Si ya había hecho check-in en esa clase, lo confirma sin duplicar.
struct AttendanceScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var permission = CameraPermission.status
    @State private var phase: Phase = .scanning

    enum Phase {
        case scanning
        case registering
        case success(String)
        case failed(String)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch permission {
            case .authorized:
                switch phase {
                case .scanning: scannerView
                case .registering: registeringView
                case .success(let message): successView(message: message)
                case .failed(let message): failedView(message: message)
                }
            case .denied:
                deniedView
            case .undetermined:
                Color.clear.task {
                    permission = await CameraPermission.request() ? .authorized : .denied
                }
            }

            closeButton
        }
        .statusBarHidden()
    }

    // MARK: - Registro en Supabase

    /// Valida el payload del QR y hace el check-in.
    private func handleScan(_ value: String) {
        guard case .scanning = phase else { return }
        guard value.hasPrefix(GenerateQRView.payloadPrefix),
              let sessionId = UUID(uuidString: String(value.dropFirst(GenerateQRView.payloadPrefix.count))) else {
            Haptics.notify(.error)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                phase = .failed("Ese código no es un QR de asistencia NDC. Pídele al coach el QR de la clase.")
            }
            return
        }
        phase = .registering
        Task {
            do {
                try await AthleteRepository().checkIn(sessionId: sessionId)
                Haptics.notify(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    phase = .success("Nos vemos en el box. ¡A entrenar! 💪")
                }
            } catch let error where AthleteRepository.isDuplicate(error) {
                Haptics.notify(.success)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    phase = .success("Tu asistencia de esta clase ya estaba registrada. 💪")
                }
            } catch {
                Haptics.notify(.error)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    phase = .failed("No se pudo registrar tu asistencia. Revisa tu conexión e inténtalo de nuevo.")
                }
            }
        }
    }

    // MARK: - Cámara + marco

    private var scannerView: some View {
        ZStack {
            QRCameraView { value in
                handleScan(value)
            }
            .ignoresSafeArea()

            // Oscurecido con "ventana" de escaneo
            Color.black.opacity(0.45).ignoresSafeArea()
                .reverseMask {
                    RoundedRectangle(cornerRadius: 24).frame(width: 260, height: 260)
                }

            ScanFrame()
                .frame(width: 260, height: 260)

            VStack {
                Spacer()
                VStack(spacing: NDCSpacing.stackSM) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 28))
                        .foregroundStyle(NDCColor.accent)
                    Text("Apunta al código QR de tu clase")
                        .font(NDCFont.headlineSM)
                        .foregroundStyle(.white)
                    Text("Tu asistencia se registrará automáticamente")
                        .font(NDCFont.bodyMD)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 80)
            }
            .padding(.horizontal, NDCSpacing.marginMain)
        }
    }

    // MARK: - Registrando (insert en curso)

    private var registeringView: some View {
        VStack(spacing: NDCSpacing.stackLG) {
            ProgressView()
                .controlSize(.large)
                .tint(NDCColor.accent)
            Text("Registrando tu asistencia…")
                .font(NDCFont.headlineSM)
                .foregroundStyle(.white)
        }
        .padding(NDCSpacing.marginMain * 2)
    }

    // MARK: - Éxito

    private func successView(message: String) -> some View {
        VStack(spacing: NDCSpacing.stackLG) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(NDCColor.accent)
                .transition(.scale.combined(with: .opacity))
            VStack(spacing: NDCSpacing.stackSM) {
                Text("¡Asistencia registrada!")
                    .font(NDCFont.headlineMD)
                    .foregroundStyle(.white)
                Text(message)
                    .font(NDCFont.bodyLG)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            Button {
                Haptics.impact()
                dismiss()
            } label: {
                Text("Listo")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
            }
            .padding(.top, NDCSpacing.stackMD)
        }
        .padding(NDCSpacing.marginMain * 2)
    }

    // MARK: - Error (QR ajeno o sin conexión)

    private func failedView(message: String) -> some View {
        VStack(spacing: NDCSpacing.stackLG) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(NDCColor.error)
                .transition(.scale.combined(with: .opacity))
            VStack(spacing: NDCSpacing.stackSM) {
                Text("No se pudo registrar")
                    .font(NDCFont.headlineMD)
                    .foregroundStyle(.white)
                Text(message)
                    .font(NDCFont.bodyLG)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            Button {
                Haptics.impact()
                withAnimation { phase = .scanning }
            } label: {
                Text("Escanear de nuevo")
                    .font(NDCFont.headlineSM)
                    .foregroundStyle(NDCColor.primary)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(NDCColor.accent, in: .rect(cornerRadius: NDCRadius.large))
            }
            .padding(.top, NDCSpacing.stackMD)
        }
        .padding(NDCSpacing.marginMain * 2)
    }

    // MARK: - Permiso denegado

    private var deniedView: some View {
        VStack(spacing: NDCSpacing.stackMD) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.7))
            Text("Cámara sin acceso")
                .font(NDCFont.headlineSM).foregroundStyle(.white)
            Text("Para escanear el QR de asistencia, activa la cámara en Ajustes.")
                .font(NDCFont.bodyMD)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Abrir Ajustes")
                    .font(NDCFont.labelBold)
                    .foregroundStyle(NDCColor.primary)
                    .padding(.horizontal, NDCSpacing.stackLG).padding(.vertical, 12)
                    .background(NDCColor.accent, in: .capsule)
            }
        }
        .padding(NDCSpacing.marginMain * 2)
    }

    // MARK: - Cerrar

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.15), in: .circle)
                }
                .accessibilityLabel("Cerrar")
            }
            Spacer()
        }
        .padding(NDCSpacing.marginMain)
    }
}

// MARK: - Marco de escaneo (esquinas animadas)

private struct ScanFrame: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<4) { i in
                corner.rotationEffect(.degrees(Double(i) * 90))
            }
            // Línea de escaneo
            Rectangle()
                .fill(LinearGradient(colors: [.clear, NDCColor.accent, .clear],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 2)
                .offset(y: animate ? 120 : -120)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear { animate = true }
        .accessibilityHidden(true)
    }

    private var corner: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 0, y: 30))
                p.addLine(to: CGPoint(x: 0, y: 8))
                p.addQuadCurve(to: CGPoint(x: 8, y: 0), control: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: 30, y: 0))
            }
            .stroke(NDCColor.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Reverse mask helper

private extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask {
            Rectangle().overlay(mask().blendMode(.destinationOut))
        }
    }
}

#Preview {
    AttendanceScannerView()
}
