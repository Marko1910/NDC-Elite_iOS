import SwiftUI
import WebKit

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

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var loadedID: String? }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true                 // reproducir en línea
        config.mediaTypesRequiringUserActionForPlayback = []    // permitir autoplay si el usuario toca
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.loadedID != videoID else { return }
        context.coordinator.loadedID = videoID
        // Se usa la IFrame Player API (JS) con baseURL en el origen de YouTube,
        // que es la forma recomendada por Google para incrustar en WKWebView y
        // evita los errores 152/153 que da el iframe cargado directamente.
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
              playerVars: { playsinline: 1, modestbranding: 1, rel: 0 }
            });
          }
        </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
    }
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
