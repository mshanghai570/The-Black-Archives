import SwiftUI

struct ArchiveCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content
    var showsPressEffect: Bool = false
    
    init(title: String, subtitle: String? = nil, showsPressEffect: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
        self.showsPressEffect = showsPressEffect
    }
    
    @State private var isPressed = false
    
    var body: some View {
        let cardContent = VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(ArchiveTypography.cinzel(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.bronze)
                    if let subtitle = subtitle {
                        Text(subtitle.uppercased())
                            .font(ArchiveTypography.courier(size: 8))
                            .foregroundColor(ArchiveColors.textMuted)
                    }
                }
                Spacer()
            }
            .padding(.bottom, 6)
            .border(width: 1, edge: .bottom, color: ArchiveColors.border)
            
            content
        }
        .padding()
        .background(ArchiveColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ArchiveColors.border, lineWidth: 1)
        )
        .scaleEffect(showsPressEffect && isPressed ? 0.98 : 1.0)
        .opacity(showsPressEffect && isPressed ? 0.9 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPressed)

        return cardContent
            .modifier(PressActionModifier(enabled: showsPressEffect) { pressed in
                if pressed {
                    isPressed = true
                    HapticFeedback.light.trigger()
                } else {
                    isPressed = false
                }
            })
    }
}
