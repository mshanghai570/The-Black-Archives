import SwiftUI

public enum ArchiveAnimations {
    public static let classicSpring = Animation.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)
    public static let buttonTap = Animation.easeInOut(duration: 0.12)
    
    public static var listTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }
}
