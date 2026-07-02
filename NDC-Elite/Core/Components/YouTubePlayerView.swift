import SwiftUI
import WebKit
import SafariServices

/// Reproductor de YouTube **embebido dentro de la app** (WKWebView con la IFrame
/// Player API de YouTube). El coach sube los videos como enlace de YouTube; aquí
/// se reproducen sin salir de la app, en línea (no a pantalla completa forzada).
///
/// NOTA: el **Simulador de iOS** muestra "Error 152" en los embeds de YouTube
/// (limitación conocida del simulador, le faltan frameworks de media). En un
/// **dispositivo real** el video reproduce; el simulador degrada al enlace
/// "Mirar el video en YouTube".
struct YouTubePlayerView: UIViewRepresentable {
    /// ID del video (11 caracteres). Usar `YouTube.videoID(from:)` para extraerlo.
    let videoID: String
    /// Arranca reproduciendo (para cuando se toca el play de la miniatura).
    var autoplay = false
    /// YouTube rechazó el embed (error 101/150/153…): permite a la vista
    /// contenedora ofrecer un plan B (navegador integrado).
    var onError: (() -> Void)?

    func makeCoordinator() -> Coordinator { Coordinator(onError: onError) }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        var loadedID: String?
        private let onError: (() -> Void)?
        init(onError: (() -> Void)?) { self.onError = onError }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            if message.name == "ytError" {
                DispatchQueue.main.async { self.onError?() }
            }
        }
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true                 // reproducir en línea
        config.mediaTypesRequiringUserActionForPlayback = []    // permitir autoplay si el usuario toca
        config.userContentController.add(context.coordinator, name: "ytError")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        return webView
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ytError")
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedID != videoID else { return }
        context.coordinator.loadedID = videoID
        // IFrame API con baseURL en youtube.com: el embed recibe un origen
        // válido (evita el error 153 por falta de Referer) y el evento onError
        // nos avisa si YouTube rechaza la reproducción embebida.
        let html = """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
        <style>*{margin:0;padding:0;}html,body{background:#000;height:100%;overflow:hidden;}
        #player{position:absolute;inset:0;width:100%;height:100%;}</style>
        </head><body>
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
          function onYouTubeIframeAPIReady() {
            new YT.Player('player', {
              width: '100%', height: '100%', videoId: '\(videoID)',
              playerVars: { playsinline: 1, rel: 0, autoplay: \(autoplay ? 1 : 0) },
              events: {
                onError: function() { window.webkit.messageHandlers.ytError.postMessage('e'); }
              }
            });
          }
        </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
}

/// Miniatura de un video de YouTube con botón de play. Carga instantánea (imagen
/// estática de img.youtube.com); al tocar, el video se reproduce **en el mismo
/// recuadro** (embed de YouTube). Si YouTube rechaza el embed, cae solo al
/// navegador integrado (SFSafariViewController) como plan B.
struct YouTubeThumbnailPlayer: View {
    let videoID: String
    @State private var isPlaying = false
    @State private var fallbackBrowser = false

    var body: some View {
        ZStack {
            if isPlaying {
                YouTubePlayerView(videoID: videoID, autoplay: true) {
                    isPlaying = false
                    fallbackBrowser = true
                }
            } else {
                Button {
                    isPlaying = true
                } label: {
                    ZStack {
                        Color.black
                        AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "video.slash")
                                    .font(.system(size: 28)).foregroundStyle(.white.opacity(0.6))
                            default:
                                ProgressView().tint(.white)
                            }
                        }
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.white, .black.opacity(0.55))
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Reproducir video")
            }
        }
        .onChange(of: videoID) { isPlaying = false }
        .sheet(isPresented: $fallbackBrowser) {
            if let url = URL(string: "https://www.youtube.com/watch?v=\(videoID)") {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

/// Navegador integrado (SFSafariViewController) para reproducir contenido web
/// sin salir de la app.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(NDCColor.primary)
        return vc
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}

/// Utilidades para enlaces de YouTube.
enum YouTube {
    /// Extrae el ID de video de cualquier formato de URL de YouTube:
    /// `watch?v=ID`, `youtu.be/ID`, `/embed/ID`, `/shorts/ID`, o el ID suelto.
    static func videoID(from urlString: String) -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            return looksLikeID(trimmed) ? trimmed : nil
        }
        if url.host?.contains("youtu.be") == true {
            return url.pathComponents.dropFirst().first
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let v = items.first(where: { $0.name == "v" })?.value {
            return v
        }
        let parts = url.pathComponents
        if let i = parts.firstIndex(where: { $0 == "embed" || $0 == "shorts" }), i + 1 < parts.count {
            return parts[i + 1]
        }
        return looksLikeID(trimmed) ? trimmed : nil
    }

    private static func looksLikeID(_ s: String) -> Bool {
        !s.contains("/") && !s.contains(".") && s.count >= 8
    }
}
