import SwiftUI

public enum ArchiveShadows {
    public static let heavy = Shadow(color: .black, radius: 10, x: 0, y: 6)
    public static let classic = Shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
}

public struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}
