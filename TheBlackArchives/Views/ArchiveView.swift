import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject var archiveVM: ArchiveViewModel
    @Binding var activeTab: Int
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    ArchiveHeader(title: "Recovered Artifacts", subtitle: "Visual Archives Store")
                    Spacer()
                    Button(action: { 
                        HapticFeedback.light.trigger()
                        activeTab = 0 
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(ArchiveColors.bronze)
                    }
                }
                .padding(.horizontal)
                
                if archiveVM.artifacts.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Text("NO RECOVERED PLATES RECORDED")
                            .font(ArchiveTypography.courier(size: 11))
                            .foregroundColor(ArchiveColors.textMuted)
                        Text("Generate images from the Console tab to populate this archive.")
                            .font(ArchiveTypography.courier(size: 9))
                            .foregroundColor(ArchiveColors.textMuted)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(archiveVM.artifacts) { artifact in
                                NavigationLink(value: artifact) {
                                    ArtifactCell(artifact: artifact)
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationDestination(for: Artifact.self) { artifact in
                        ImageDetailView(artifact: artifact)
                    }
                }
            }
            .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width > 100 {
                        HapticFeedback.light.trigger()
                        activeTab = 0
                    }
                }
        )
    }
}

struct ArtifactCell: View {
    let artifact: Artifact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let imageData = artifact.loadImageData(),
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .clipped()
                    .cornerRadius(4)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)
                    .cornerRadius(4)
                    .overlay(
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .foregroundColor(ArchiveColors.textMuted)
                            Text("NO DATA")
                                .font(ArchiveTypography.courier(size: 8))
                                .foregroundColor(ArchiveColors.textMuted)
                        }
                    )
            }
            
            Text(artifact.prompt)
                .font(ArchiveTypography.courier(size: 8))
                .foregroundColor(ArchiveColors.text)
                .lineLimit(2)
            
            HStack {
                Text(artifact.modelId)
                    .font(ArchiveTypography.courier(size: 7))
                    .foregroundColor(ArchiveColors.textMuted)
                Spacer()
                Text(artifact.timestamp, style: .relative)
                    .font(ArchiveTypography.courier(size: 7))
                    .foregroundColor(ArchiveColors.textMuted)
            }
        }
        .padding(8)
        .background(ArchiveColors.cardBackground)
        .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(ArchiveColors.border, lineWidth: 1)
            )
    }
}
