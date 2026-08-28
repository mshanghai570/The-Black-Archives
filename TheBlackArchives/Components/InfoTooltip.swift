import SwiftUI

struct InfoTooltip: View {
    let text: String
    @State private var showTip = false
    
    var body: some View {
        Button(action: {
            HapticFeedback.light.trigger()
            showTip.toggle()
        }) {
            Image(systemName: showTip ? "questionmark.circle.fill" : "questionmark.circle")
                .font(.system(size: 14))
                .foregroundColor(ArchiveColors.textMuted)
        }
        .buttonStyle(ScaleButtonStyle())
        .popover(isPresented: $showTip) {
            Text(text)
                .font(ArchiveTypography.courier(size: 10))
                .foregroundColor(ArchiveColors.text)
                .padding(12)
                .frame(maxWidth: 250)
                .background(ArchiveColors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ArchiveColors.border, lineWidth: 1)
                )
        }
    }
}
