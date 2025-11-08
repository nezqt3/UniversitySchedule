import SwiftUI

/// Универсальный glass-контейнер для macOS (и iOS, если надо).
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 14
    var padding: CGFloat = 12
    var shadowRadius: CGFloat = 12
    var borderOpacity: Double = 0.12
    var content: () -> Content

    init(
        cornerRadius: CGFloat = 14,
        padding: CGFloat = 12,
        shadowRadius: CGFloat = 12,
        borderOpacity: Double = 0.12,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderOpacity = borderOpacity
        self.content = content
    }

    var body: some View {
        ZStack {
            // ✅ Материал / блюр (современные macOS)
            backgroundShape

            // 💡 Лёгкий градиент подсветки сверху
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(borderOpacity),
                            Color.black.opacity(borderOpacity * 0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .blendMode(.overlay)

            // Контент
            content()
                .padding(padding)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.18), radius: shadowRadius, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.03), lineWidth: 1)
                .blendMode(.overlay)
        )
    }

    // MARK: - Background shape (фикс)
    @ViewBuilder
    private var backgroundShape: some View {
        if #available(macOS 12.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(.clear)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .background(.clear)
                .overlay(
                    VisualEffectBlur(blurRadius: 8)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                )
        }
    }
}

// Простая реализация blur для fallback (если не нужна - можно убрать)
struct VisualEffectBlur: NSViewRepresentable {
    let blurRadius: CGFloat

    init(blurRadius: CGFloat = 8) {
        self.blurRadius = blurRadius
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.material = .hudWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
