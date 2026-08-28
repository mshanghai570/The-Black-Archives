import SwiftUI

struct ArchiveHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(ArchiveTypography.cinzel(size: 18))
                .fontWeight(.bold)
                .foregroundColor(ArchiveColors.text)
                .tracking(2.0)
            
            Text(subtitle.uppercased())
                .font(ArchiveTypography.courier(size: 8))
                .foregroundColor(ArchiveColors.bronze)
                .tracking(1.5)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
