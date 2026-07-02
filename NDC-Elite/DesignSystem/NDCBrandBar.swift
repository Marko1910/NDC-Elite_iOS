import SwiftUI

/// Botón de notificaciones con rebote cuando hay sin leer.
struct NDCBellButton: View {
    let unreadCount: Int
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: "bell")
                .foregroundStyle(NDCColor.primary)
                .symbolEffect(.bounce, value: unreadCount)
        }
        .accessibilityLabel("Notificaciones")
        .accessibilityValue(unreadCount > 0 ? "\(unreadCount) sin leer" : "Sin novedades")
    }
}

/// Avatar circular reutilizable con borde de marca y fallback de sistema.
struct NDCAvatarView: View {
    let urlString: String?
    let size: CGFloat

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(.circle)
        .overlay(Circle().stroke(NDCColor.primary, lineWidth: 2))
    }

    private var placeholder: some View {
        Image(systemName: "person.fill")
            .foregroundStyle(NDCColor.primary)
            .frame(width: size, height: size)
            .background(NDCColor.surface)
    }
}
