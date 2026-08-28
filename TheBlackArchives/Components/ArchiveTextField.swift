import SwiftUI

struct ArchiveTextField: View {
    let placeholder: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundColor(ArchiveColors.textMuted))
            .font(ArchiveTypography.courier(size: 11))
            .foregroundColor(ArchiveColors.text)
            .padding(12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ArchiveColors.border, lineWidth: 1)
            )
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                    .font(ArchiveTypography.courier(size: 12))
                    .foregroundColor(ArchiveColors.bronze)
                }
            }
    }
}
