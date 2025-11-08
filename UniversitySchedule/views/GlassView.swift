import SwiftUI

struct TahoeGlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 16
    var padding: CGFloat = 12
    var shadowRadius: CGFloat = 15
    var content: () -> Content

    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 12,
        shadowRadius: CGFloat = 15,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.content = content
    }

    var body: some View {
        ZStack {
            // Единый фон
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.15), // тёмное стекло
                            Color.black.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            content()
                .padding(padding)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 6)
    }
}


// Tahoe blur под macOS Tahoe
struct TahoeVisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .underWindowBackground
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 20
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
