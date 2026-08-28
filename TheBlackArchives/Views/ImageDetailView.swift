import SwiftUI

struct ImageDetailView: View {
    let artifact: Artifact
    @EnvironmentObject var archiveVM: ArchiveViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ArchiveHeader(title: "Plate Inspector", subtitle: "Detail Evaluation")
                
                if let imageData = artifact.loadImageData(),
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(ArchiveColors.border, lineWidth: 1)
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 280)
                        .cornerRadius(4)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(ArchiveColors.textMuted)
                                Text("NO IMAGE DATA")
                                    .font(ArchiveTypography.courier(size: 9))
                                    .foregroundColor(ArchiveColors.textMuted)
                            }
                        )
                }
                
                ArchiveCard(title: "Diffusion Metrics", subtitle: "Engine Logs") {
                    VStack(alignment: .leading, spacing: 8) {
                        MetricRow(label: "Sourcing Seed", value: "\(artifact.seed)")
                        MetricRow(label: "Model Sourced", value: artifact.modelId)
                        MetricRow(label: "Hardware Engine", value: artifact.engine)
                        MetricRow(label: "Latency", value: String(format: "%.3fs", artifact.latencySeconds))
                        MetricRow(label: "Prompt", value: artifact.prompt)
                        MetricRow(label: "Timestamp", value: artifact.timestamp.formatted())
                    }
                }
                
                ArchiveCard(title: "Actions") {
                    VStack(spacing: 10) {
                        ArchiveButton(title: "Share Image", icon: "square.and.arrow.up") {
                            showShareSheet = true
                        }
                        
                        ArchiveButton(title: "Delete Artifact", icon: "trash") {
                            showDeleteConfirm = true
                        }
                    }
                }
            }
            .padding()
        }
        .background(ArchiveColors.background.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showShareSheet) {
            if let imageData = artifact.loadImageData() {
                ShareSheet(items: [imageData])
            }
        }
        .alert("Delete Artifact", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                archiveVM.removeArtifact(id: artifact.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove this generated image from the archive.")
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label.uppercased())
                .font(ArchiveTypography.courier(size: 8.5))
                .foregroundColor(ArchiveColors.textMuted)
            Spacer()
            Text(value)
                .font(ArchiveTypography.courier(size: 9))
                .foregroundColor(ArchiveColors.text)
                .multilineTextAlignment(.trailing)
        }
    }
}
