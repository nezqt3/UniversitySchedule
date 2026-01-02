import SwiftUI

struct TahoeGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 22 // В виджетах macOS углы чуть более скругленные
    var padding: CGFloat = 16
    var content: () -> Content

    var body: some View {
        ZStack {
            // 1. Основной системный блюр (материал для виджетов)
            TahoeVisualEffectBlur(material: .fullScreenUI, blendingMode: .withinWindow)
            
            // 2. Слой легкого высветления (чтобы стекло не было слишком черным)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.03))
            
            // 3. Внутреннее свечение (Inner Bevel/Glow)
            // Именно оно создает эффект "толстого" дорогого стекла
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.15), // Свет падает сверху
                            .white.opacity(0.05),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .padding(0.5) // Чуть утапливаем внутрь
            
            // 4. Тончайший внешний контур (Border)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.black.opacity(0.4), lineWidth: 0.5)

            // Контент
            content()
                .padding(padding)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        // Важно: в macOS тени у виджетов очень глубокие, но мягкие
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }
}

struct TahoeVisualEffectBlur: NSViewRepresentable {
    // Для эффекта как в Центре Уведомлений лучше всего подходит .fullScreenUI или .contentBackground
    var material: NSVisualEffectView.Material = .fullScreenUI
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}
