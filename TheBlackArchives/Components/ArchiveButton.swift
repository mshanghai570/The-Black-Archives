import SwiftUI
import UIKit

struct ArchiveButton: View {
    let title: String
    var icon: String? = nil
    var isAccent: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedback.medium.trigger()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title.uppercased())
                    .font(ArchiveTypography.courier(size: 11))
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isAccent ? ArchiveColors.bronze.opacity(0.15) : ArchiveColors.cardBackground)
            .foregroundColor(isAccent ? ArchiveColors.bronze : ArchiveColors.text)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isAccent ? ArchiveColors.bronze : ArchiveColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
