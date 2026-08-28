import SwiftUI

struct LoadingOverlay: View {
    let progress: Int
    let message: String
    
    @State private var isPulsing = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Animated pulse loader
                ZStack {
                    Circle()
                        .stroke(ArchiveColors.border.opacity(0.3), lineWidth: 3)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(ArchiveColors.bronze, lineWidth: 3)
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(isPulsing ? 360 : 0))
                        .animation(
                            .linear(duration: 1.2)
                            .repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                    
                    // Inner pulse dot
                    Circle()
                        .fill(ArchiveColors.bronze)
                        .frame(width: 8, height: 8)
                        .offset(y: -20)
                        .opacity(isPulsing ? 0.3 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                .onAppear {
                    isPulsing = true
                }
                
                VStack(spacing: 8) {
                    Text("\(progress)% COMPLETED")
                        .font(ArchiveTypography.courier(size: 12))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.text)
                        .transition(.opacity)
                    
                    Text(message)
                        .font(ArchiveTypography.courier(size: 9))
                        .foregroundColor(ArchiveColors.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }
}
