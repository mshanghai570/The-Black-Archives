import SwiftUI
import CoreText

public enum ArchiveTypography {
    public static func registerCustomFonts() {
        // Fonts are registered automatically by iOS when included as
        // resources in the app bundle; this hook exists for parity with
        // callers that expect explicit registration.
    }

    public static func cinzel(size: CGFloat) -> Font {
        Font.custom("Cinzel-Regular", size: size)
    }
    
    public static func courier(size: CGFloat) -> Font {
        Font.custom("CourierPrime-Regular", size: size)
    }
}
