import SwiftUI

// Scale effect button style for press feedback
public struct ScaleButtonStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

// Press action modifier for custom press effects
struct PressButtonStyle: ButtonStyle {
    let action: (Bool) -> Void
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                action(newValue)
            }
    }
}

public struct PressActionModifier: ViewModifier {
    let enabled: Bool
    let action: (Bool) -> Void
    
    public func body(content: Content) -> some View {
        if enabled {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in action(true) }
                        .onEnded { _ in action(false) }
                )
        } else {
            content
        }
    }
}

// Extension for press detection on any view
extension View {
    public func pressAction(_ action: @escaping (Bool) -> Void) -> some View {
        self.modifier(PressActionModifier(enabled: true, action: action))
    }
}
