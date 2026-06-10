import UIKit

/// Abre WhatsApp con un recordatorio de inasistencia pre-armado.
/// Usado por el botón "Contactar Atleta" del coach (ver FLOWS.md):
/// no hay chat interno en v1, el contacto va por WhatsApp.
enum WhatsAppHelper {
    /// - Parameters:
    ///   - phone: número con código de país, ej. "+51987654321" (profiles.phone)
    ///   - athleteName: nombre de pila del atleta
    ///   - absentDays: días sin asistir (calculado de attendance)
    static func sendAbsenceReminder(phone: String, athleteName: String, absentDays: Int) {
        let message = """
        Hola \(athleteName) 👋 Te extrañamos en NDC HQ. \
        Llevas \(absentDays) días sin entrenar. ¿Todo bien? \
        ¡Tu próxima clase te espera! 💪
        """
        let digits = phone.filter(\.isNumber)
        guard
            let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "https://wa.me/\(digits)?text=\(encoded)")
        else { return }

        UIApplication.shared.open(url)
    }
}
