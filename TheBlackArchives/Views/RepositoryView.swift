import SwiftUI
import UniformTypeIdentifiers

struct RepositoryView: View {
    @EnvironmentObject var repoVM: RepositoryViewModel
    @Binding var activeTab: Int
    @State private var searchQuery = ""
    @State private var showDocumentPicker = false
    @State private var lastDragPosition: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ArchiveHeader(title: "Model Repository", subtitle: "Local and Remote Weights")
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
            
            HStack {
                ArchiveTextField(placeholder: "Search HuggingFace hubs...", text: $searchQuery)
                
                Menu {
                    Text("Format detected automatically")
                    Divider()
                    Button("Import web-downloaded generator") { showDocumentPicker = true }
                } label: {
                    Image(systemName: ArchiveIcons.download)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ArchiveColors.bronze)
                        .padding(10)
                        .background(ArchiveColors.cardBackground)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ArchiveColors.border, lineWidth: 1))
                }
            }
            .padding(.horizontal)
            
            HStack {
                Button(action: { showDocumentPicker = true }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("IMPORT DOWNLOADED GENERATOR")
                    }
                    .font(ArchiveTypography.courier(size: 9))
                    .fontWeight(.bold)
                    .foregroundColor(ArchiveColors.bronze)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(ArchiveColors.bronze.opacity(0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(ArchiveColors.bronze.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 4)

            Text("Import an unzipped generator folder, a checkpoint file, or select its companion files together. ZIP downloads can be expanded in Files first.")
                .font(ArchiveTypography.courier(size: 8))
                .foregroundColor(ArchiveColors.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Error banners — search and download failures were previously
            // swallowed; surface them so the user knows why nothing happened.
            if let message = repoVM.importStatusMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ArchiveColors.green)
                        .font(.system(size: 12))
                    Text(message)
                        .font(ArchiveTypography.courier(size: 8.5))
                        .foregroundColor(ArchiveColors.green)
                    Spacer()
                }
                .padding(10)
                .background(ArchiveColors.green.opacity(0.08))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ArchiveColors.green.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
            }

            if let error = repoVM.downloadErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: ArchiveIcons.warning)
                        .foregroundColor(.red)
                        .font(.system(size: 12))
                    Text(error)
                        .font(ArchiveTypography.courier(size: 8.5))
                        .foregroundColor(.red)
                        .lineLimit(3)
                    Spacer()
                }
                .padding(10)
                .background(Color.red.opacity(0.08))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
            }
            
            if let error = repoVM.searchError {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: ArchiveIcons.warning)
                        .foregroundColor(ArchiveColors.bronze)
                        .font(.system(size: 12))
                    Text("Search failed: \(error)")
                        .font(ArchiveTypography.courier(size: 8.5))
                        .foregroundColor(ArchiveColors.text)
                        .lineLimit(3)
                    Spacer()
                }
                .padding(10)
                .background(ArchiveColors.bronze.opacity(0.08))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ArchiveColors.bronze.opacity(0.3), lineWidth: 1))
                .padding(.horizontal)
            }
            
            let filtered = repoVM.models.filter { query in
                let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                guard !q.isEmpty else { return true }
                return query.name.lowercased().contains(q)
                    || query.author.lowercased().contains(q)
                    || query.description.lowercased().contains(q)
                    || query.format.rawValue.lowercased().contains(q)
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    if !filtered.isEmpty {
                        Text("LOCAL CATALOG")
                            .font(ArchiveTypography.courier(size: 8))
                            .foregroundColor(ArchiveColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(filtered) { model in
                            RepositoryRow(model: model)
                                .background(ArchiveColors.cardBackground)
                                .padding(.horizontal)
                        }
                    }
                    
                    if repoVM.isSearching {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: ArchiveColors.bronze))
                            Spacer()
                        }
                        .padding(.vertical, 20)
                    } else if !repoVM.hfSearchResults.isEmpty {
                        Text("HUGGINGFACE HUBS")
                            .font(ArchiveTypography.courier(size: 8))
                            .foregroundColor(ArchiveColors.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        ForEach(repoVM.hfSearchResults) { model in
                            RepositoryRow(model: model)
                                .background(ArchiveColors.cardBackground)
                                .padding(.horizontal)
                        }
                    } else if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 30))
                                .foregroundColor(ArchiveColors.textMuted)
                            
                            Text("NO ONLINE MODELS FOUND")
                                .font(ArchiveTypography.courier(size: 11))
                                .foregroundColor(ArchiveColors.textMuted)
                                .fontWeight(.bold)
                            
                            Text("Try a different search query")
                                .font(ArchiveTypography.courier(size: 9))
                                .foregroundColor(ArchiveColors.textMuted.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .refreshable {
                HapticFeedback.light.trigger()
                if !searchQuery.isEmpty {
                    await repoVM.searchHuggingFace(query: searchQuery)
                }
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
            .sheet(isPresented: $showDocumentPicker) {
                LocalModelImporter(isPresented: $showDocumentPicker) { urls in
                    // Keep every selected companion file. This is important for
                    // web downloads that separate the checkpoint, VAE, and
                    // text encoder into a single generator folder.
                    repoVM.importLocalModels(urls: urls, format: nil)
                }
            }
            .onChange(of: repoVM.downloadErrorMessage) { _, newValue in
                if newValue != nil { repoVM.importStatusMessage = nil }
            }
            .onChange(of: searchQuery) { oldValue, newValue in
                repoVM.searchHuggingFace(query: newValue)
            }
        }
    }
}

struct RepositoryRow: View {
    let model: AIModel
    @EnvironmentObject var repoVM: RepositoryViewModel

    /// True for models discovered via the HuggingFace search (remote repos).
    private var isRemote: Bool {
        !model.isLocalCatalog && !(model.author == "Local Import")
    }
    
    /// True if this is a catalog model that can be downloaded from HuggingFace.
    private var isDownloadableCatalog: Bool {
        model.isLocalCatalog && !model.isInstalled
    }

    private var isSelected: Bool {
        repoVM.selectedModelId == model.id && model.isInstalled
    }

    private var isDownloading: Bool {
        repoVM.downloadingModelId == model.id
    }

    var body: some View {
        Button(action: {
            if model.isInstalled {
                repoVM.selectModel(id: model.id)
            } else {
                Task { await repoVM.downloadAndInstall(from: model) }
            }
        }) {
            HStack(spacing: 10) {
                if isDownloading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: ArchiveColors.bronze))
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : (model.isInstalled ? "circle.fill" : ArchiveIcons.download))
                        .foregroundColor(isSelected ? ArchiveColors.green : (model.isInstalled ? ArchiveColors.bronze : (isRemote || isDownloadableCatalog ? ArchiveColors.bronze : ArchiveColors.textMuted)))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(model.name)
                            .font(ArchiveTypography.courier(size: 11))
                            .fontWeight(.bold)
                            .foregroundColor(ArchiveColors.text)
                        if isSelected {
                            Text("ACTIVE")
                                .font(ArchiveTypography.courier(size: 7))
                                .foregroundColor(ArchiveColors.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(ArchiveColors.green.opacity(0.12))
                                .cornerRadius(3)
                        }
                        if isRemote && !model.isInstalled {
                            Text("HF")
                                .font(ArchiveTypography.courier(size: 7))
                                .foregroundColor(ArchiveColors.bronze)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(ArchiveColors.bronze.opacity(0.12))
                                .cornerRadius(3)
                        }
                    }

                    Text(model.description)
                        .font(ArchiveTypography.courier(size: 8.5))
                        .foregroundColor(ArchiveColors.textMuted)
                        .lineLimit(2)

                    if isDownloading {
                        VStack(alignment: .leading, spacing: 2) {
                            ProgressView(value: repoVM.downloadProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: ArchiveColors.bronze))
                                .frame(maxWidth: 200)
                            Text(repoVM.downloadStatus.isEmpty ? "DOWNLOADING…" : repoVM.downloadStatus.uppercased())
                                .font(ArchiveTypography.courier(size: 7.5))
                                .foregroundColor(ArchiveColors.bronze)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    } else {
                        Text("\(model.format.rawValue) · \(ByteCountFormatter.string(fromByteCount: model.fileSizeBytes, countStyle: .decimal))")
                            .font(ArchiveTypography.courier(size: 7.5))
                            .foregroundColor(ArchiveColors.bronze.opacity(0.8))
                    }
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
