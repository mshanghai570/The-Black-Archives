import SwiftUI

struct OnboardingView: View {
    @State private var hasAccepted = false
    @EnvironmentObject var homeVM: HomeViewModel
    
    var body: some View {
        if hasAccepted {
            HomeView()
        } else {
            VStack(spacing: 30) {
                Spacer()
                
                ArchiveHeader(
                    title: "The Black Archives",
                    subtitle: "Secure Local Generative Framework"
                )
                
                VStack(alignment: .leading, spacing: 15) {
                    Text("LICENSE MATRICES & ETHICS PROTOCOL")
                        .font(ArchiveTypography.cinzel(size: 11))
                        .fontWeight(.bold)
                        .foregroundColor(ArchiveColors.bronze)
                    
                    Text("This software processes local latent arrays solely inside sandbox hardware storage. By executing local generative pipelines, you confirm full ownership of models and accept local execution compliance guides.")
                        .font(ArchiveTypography.courier(size: 9.5))
                        .foregroundColor(ArchiveColors.textMuted)
                        .lineSpacing(4)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .border(ArchiveColors.border, width: 1)
                .padding(.horizontal, 24)
                
                Spacer()
                
                ArchiveButton(title: "Initialize Secure Core", isAccent: true) {
                    withAnimation {
                        hasAccepted = true
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
            .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
        }
    }
}
