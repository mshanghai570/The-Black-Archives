import SwiftUI

struct ArchiveSection<Content: View>: View {
    let headerTitle: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.headerTitle = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(headerTitle.uppercased())
                .font(ArchiveTypography.courier(size: 9))
                .fontWeight(.bold)
                .foregroundColor(ArchiveColors.textMuted)
                .tracking(1.5)
            
            content
        }
    }
}
