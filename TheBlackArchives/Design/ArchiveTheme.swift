import SwiftUI

public enum ArchiveTheme {
    public static let borderWidth: CGFloat = 1.0
    public static let cornerRadius: CGFloat = 8.0
    
    public static func paperBorder<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding()
            .background(ArchiveColors.cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ArchiveColors.border, lineWidth: borderWidth)
            )
            .shadow(color: ArchiveColors.shadow, radius: 4, x: 0, y: 2)
    }
}
