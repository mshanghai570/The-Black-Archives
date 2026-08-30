import SwiftUI
import UniformTypeIdentifiers

public final class RepositoryViewModel: ObservableObject {
    @Published public var models: [AIModel] = []
    @Published public var selectedModelId: String?
    @Published public var hfSearchResults: [AIModel] = []
    @Published public var isSearching = false
    @Published public var searchError: String? = nil
    @Published public var downloadErrorMessage: String? = nil
    @Published public var downloadingModelId: String? = nil
    @Published public var downloadProgress: Double = 0
    /// Human-readable stage of the in-flight download (manifest → file →
    /// validation) so the UI can show where a download is stuck.
    @Published public var downloadStatus: String = ""
    @Published public var importStatusMessage: String?
    
    private let hfService = HuggingFaceService()
    private var searchTask: Task<Void, Never>?
    
    public init() {
        self.models = Self.catalog
        if let data = UserDefaults.standard.data(forKey: "installed_models"),
           let saved = try? JSONDecoder().decode([AIModel].self, from: data) {
            // Merge persisted install/selection state into the catalog. Saved
            // models that are no longer in the catalog are kept only when they
            // have real weight files on disk (stale "installed" entries from
            // older versions with no downloads are pruned).
            var merged = Self.catalog
            var imported: [AIModel] = []
            for savedModel in saved {
                if let idx = merged.firstIndex(where: { $0.id == savedModel.id }) {
                    // Only restore the installed flag when the weights actually
                    // exist on disk; a stale "installed" entry from an earlier
                    // failed download must not block a re-download.
                    merged[idx].isInstalled = savedModel.isInstalled && ModelManager.shared.checkModelExists(id: savedModel.id)
                } else if savedModel.isInstalled && ModelManager.shared.checkModelExists(id: savedModel.id) {
                    imported.append(savedModel)
                }
            }
            self.models = merged + imported
        }
        if let first = models.first(where: { $0.isInstalled }) {
            self.selectedModelId = first.id
        }
    }
    
    public var selectedModel: AIModel? {
        models.first { $0.id == selectedModelId }
    }
    
    /// Downloads a model's weight files from HuggingFace into local storage,
    /// validates them, and only then marks the model installed + selects it.
    ///
    /// Catalog models carry a manifest (`repoId` + `downloadFiles`); remote
    /// search results fall back to best-effort single-file discovery.
    @MainActor
    public func downloadAndInstall(from model: AIModel) async {
        downloadingModelId = model.id
        downloadProgress = 0
        downloadErrorMessage = nil
        downloadStatus = "Resolving model manifest…"
        defer {
            downloadingModelId = nil
            downloadProgress = 0
            downloadStatus = ""
        }
        do {
            // Fail fast with a readable reason if the device can't reach
            // HuggingFace at all (offline, cellular disabled, blocked network).
            downloadStatus = "Checking network…"
            if let problem = await hfService.checkConnectivity() {
                downloadErrorMessage = problem
                Logger.error("HF connectivity check failed: \(problem)")
                return
            }

            // Resolve the file manifest for this model.
            let repoId: String
            let files: [(filename: String, size: Int64)]
            if let manifestRepo = model.repoId, let names = model.downloadFiles, !names.isEmpty {
                repoId = manifestRepo
                downloadStatus = "Resolving model manifest…"
                let available = try await hfService.listFiles(repoId: repoId)
                // Keep manifest order and fail loudly if any file is missing.
                var resolved: [(filename: String, size: Int64)] = []
                for name in names {
                    guard let match = available.first(where: { $0.filename == name }) else {
                        throw NSError(domain: "RepositoryViewModel", code: -4,
                                      userInfo: [NSLocalizedDescriptionKey: "\"\(name)\" is not in repo \(repoId). The model manifest is out of date."])
                    }
                    resolved.append(match)
                }
                files = resolved
            } else {
                repoId = model.id
                let best = try await hfService.bestWeightFile(repoId: model.id)
                files = [(best.filename, best.size)]
            }
            guard !files.isEmpty else {
                throw NSError(domain: "RepositoryViewModel", code: -4,
                              userInfo: [NSLocalizedDescriptionKey: "No downloadable files found for \(model.name)."])
            }

            let destDir = ModelManager.shared.getLocalModelURL(id: model.id)
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

            // Download every file, reporting overall progress across the set.
            // Weights fall back to 1 per file when the API reports unknown sizes.
            let weights = files.map { max($0.size, 1) }
            let totalExpected = weights.reduce(Int64(0), +)
            var receivedTotal: Int64 = 0
            for (index, file) in files.enumerated() {
                let weight = weights[index]
                let destURL = destDir.appendingPathComponent(file.filename)
                downloadStatus = "Downloading \(file.filename)"
                try await hfService.downloadFile(repoId: repoId, filename: file.filename, to: destURL) { [weak self] fraction, receivedBytes, totalBytes in
                    Task { @MainActor in
                        guard let self else { return }
                        // Use actual bytes received for progress when available,
                        // falling back to fraction-based calculation. This handles
                        // chunked downloads where totalBytes is 0.
                        let received: Int64
                        if totalBytes > 0 {
                            // Known total: use fraction
                            received = Int64(Double(weight) * min(max(fraction, 0), 1))
                        } else if receivedBytes > 0 {
                            // Unknown total (chunked): use actual bytes received
                            // Scale by weight ratio to maintain consistent progress
                            received = Int64(Double(receivedBytes) * Double(weight) / max(Double(file.size), 1))
                        } else {
                            // Fallback to fraction-based
                            received = Int64(Double(weight) * min(max(fraction, 0), 1))
                        }
                        self.downloadProgress = min(1, Double(receivedTotal + received) / Double(totalExpected))
                        // Bytes-based status: unambiguous on any connection speed.
                        self.downloadStatus = "Downloading \(file.filename) — \(Self.byteString(receivedBytes)) / \(Self.byteString(totalBytes))"
                    }
                }
                receivedTotal += weight
            }
            downloadStatus = "Validating…"
            Logger.info("Download completed for \(model.id), validating...")

            // Validate the result before marking anything installed: the folder
            // must contain a usable checkpoint, nothing may be zero-byte, and
            // every file must match its manifest size (catches silent
            // truncation that byte-count checks alone would miss). Leftover
            // `.part` files from interrupted downloads are ignored here — they
            // are the resume mechanism, not part of the installed model.
            let contents = try FileManager.default.contentsOfDirectory(at: destDir, includingPropertiesForKeys: [.fileSizeKey])
            let modelFiles = contents.filter { !$0.lastPathComponent.hasSuffix(".part") }
            let hasDiffusionFile = modelFiles.contains { fileURL in
                ["gguf", "safetensors", "ckpt", "bin", "mlpackage", "mlmodelc", "mlmodel"].contains(fileURL.pathExtension.lowercased())
            }
            guard hasDiffusionFile else {
                throw NSError(domain: "RepositoryViewModel", code: -5,
                              userInfo: [NSLocalizedDescriptionKey: "Downloaded files don't include a usable model checkpoint."])
            }
            let emptyFiles = modelFiles.filter {
                ((try? $0.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) == 0
            }
            guard emptyFiles.isEmpty else {
                throw NSError(domain: "RepositoryViewModel", code: -6,
                              userInfo: [NSLocalizedDescriptionKey: "Download incomplete — \(emptyFiles.map { $0.lastPathComponent }.joined(separator: ", ")) is empty."])
            }
            for file in files where file.size > 0 {
                let onDisk = (try? destDir.appendingPathComponent(file.filename).resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                guard onDisk == file.size else {
                    throw NSError(domain: "RepositoryViewModel", code: -7,
                                  userInfo: [NSLocalizedDescriptionKey: "\(file.filename) is incomplete (\(onDisk) of \(file.size) bytes). Tap Download again to resume."])
                }
            }
            // A completed .safetensors must carry a parseable header. A download
            // that delivered the right byte count but wrote garbage (e.g. a
            // cached HTML error page, or misaligned chunk splicing) would pass
            // every size check and then fail to load in the native engine — so
            // validate the header here and wipe the file so the next tap
            // re-downloads cleanly instead of installing a corrupt model.
            for modelFile in modelFiles where modelFile.pathExtension.lowercased() == "safetensors" {
                if !Self.isValidSafetensorsHeader(at: modelFile) {
                    try? FileManager.default.removeItem(at: modelFile)
                    throw NSError(domain: "RepositoryViewModel", code: -8,
                                  userInfo: [NSLocalizedDescriptionKey: "\(modelFile.lastPathComponent) is corrupted (failed safetensors header validation) and was removed. Tap Download again."])
                }
            }
            // Success: drop any resume partials for this model.
            for url in contents where url.lastPathComponent.hasSuffix(".part") {
                try? FileManager.default.removeItem(at: url)
            }

            // Success: register the install and select the model.
            if !models.contains(where: { $0.id == model.id }) {
                var imported = model
                imported.isInstalled = true
                imported.localFileURL = destDir.path
                models.append(imported)
            } else if let idx = models.firstIndex(where: { $0.id == model.id }) {
                models[idx].isInstalled = true
                models[idx].localFileURL = destDir.path
            }
            selectModel(id: model.id)
            saveModels()
            Logger.info("Downloaded and installed: \(model.id) -> \(destDir.path)")
        } catch {
            Logger.error("HF download failed: \(error.localizedDescription)")
            // Append a live network diagnosis so a blocked/offline path is
            // explained instead of ending in a cryptic timeout.
            var message = error.localizedDescription
            if let problem = await hfService.checkConnectivity() {
                message += " · \(problem)"
            }
            downloadErrorMessage = message
        }
    }

    /// Human-friendly byte count ("2.1 GB", "128 MB") for download status.
    private static func byteString(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: max(bytes, 0))
    }

    /// Cheap structural validation of a `.safetensors` file (shared helper on
    /// ModelManager). Deleted in this class — see ModelManager.
    private static func isValidSafetensorsHeader(at url: URL) -> Bool {
        ModelManager.isValidSafetensorsHeader(at: url)
    }
    
    /// Debounced search of HuggingFace repository for diffusion/text-to-image models.
    public func searchHuggingFace(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            self.hfSearchResults = []
            self.isSearching = false
            self.searchError = nil
            return
        }
        
        searchTask?.cancel()
        isSearching = true
        searchError = nil
        
        searchTask = Task {
            // Wait 300ms debounce
            try? await Task.sleep(nanoseconds: 300_000_000)
            if Task.isCancelled { return }
            
            do {
                let results = try await hfService.searchModels(query: trimmed)
                if Task.isCancelled { return }
                await MainActor.run {
                    self.hfSearchResults = results
                    self.isSearching = false
                }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.searchError = error.localizedDescription
                    self.isSearching = false
                }
            }
        }
    }
    
    /// Imports one or more model items from Files. This supports a single
    /// checkpoint, a downloaded generator folder, or a multi-file selection
    /// containing a checkpoint plus VAE/text encoder/tokenizer companions.
    /// Nothing is registered until the copied package passes structural checks.
    @MainActor
    public func importLocalModels(urls: [URL], format: AIModel.ModelFormat? = nil) {
        guard !urls.isEmpty else { return }
        importStatusMessage = "Inspecting downloaded generator…"
        downloadErrorMessage = nil
        let first = urls[0]
        let baseName = first.hasDirectoryPath
            ? first.lastPathComponent
            : first.deletingPathExtension().lastPathComponent
        let name = baseName.isEmpty ? "Imported Generator" : baseName
        let idBase = name.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let id = idBase.isEmpty ? "imported-generator" : idBase
        let resolvedFormat = format ?? Self.formatForURL(first)
        let destination = ModelManager.shared.getLocalModelURL(id: id)
        let staging = destination.deletingLastPathComponent().appendingPathComponent(".import-\(id)-\(UUID().uuidString)")

        do {
            let fm = FileManager.default
            try fm.createDirectory(at: staging, withIntermediateDirectories: true)
            for source in urls {
                let accessed = source.startAccessingSecurityScopedResource()
                defer { if accessed { source.stopAccessingSecurityScopedResource() } }
                try Self.copyImportItem(source, into: staging, fileManager: fm)
            }

            guard ModelManager.hasUsableModelFiles(at: staging, fileManager: fm) else {
                throw NSError(domain: "RepositoryViewModel", code: -21, userInfo: [NSLocalizedDescriptionKey: "No usable generator weights were found. Choose a .safetensors, .gguf, .ckpt, Core ML package, or a folder containing one."])
            }
            try? fm.removeItem(at: destination)
            try fm.moveItem(at: staging, to: destination)

            let fileSize = Self.sizeOfItem(at: destination)
            if let idx = models.firstIndex(where: { $0.id == id }) {
                models[idx].isInstalled = true
            } else {
                models.append(AIModel(
                    id: id,
                    name: name,
                    author: "Local Import",
                    description: "Imported from web download or Files",
                    fileSizeBytes: Int64(fileSize),
                    format: resolvedFormat,
                    isInstalled: true,
                    isLocalCatalog: true
                ))
            }
            selectModel(id: id)
            saveModels()
            importStatusMessage = "Imported \(name) — ready for local generation."
            Logger.info("Imported generator: \(name) (\(resolvedFormat.rawValue))")
        } catch {
            try? FileManager.default.removeItem(at: staging)
            importStatusMessage = nil
            downloadErrorMessage = "Import failed: \(error.localizedDescription)"
            Logger.error("Model import failed: \(error.localizedDescription)")
        }
    }

    /// Backward-compatible single-item entry point used by older screens.
    @MainActor
    public func importLocalModel(url: URL, format: AIModel.ModelFormat? = nil) {
        importLocalModels(urls: [url], format: format)
    }

    private static func copyImportItem(_ source: URL, into destination: URL, fileManager: FileManager) throws {
        let ext = source.pathExtension.lowercased()
        let destinationItem = destination.appendingPathComponent(source.lastPathComponent)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: source.path, isDirectory: &isDirectory) else {
            throw NSError(domain: "RepositoryViewModel", code: -22, userInfo: [NSLocalizedDescriptionKey: "The selected item cannot be read."])
        }
        if isDirectory.boolValue && (ext == "mlmodelc" || ext == "mlpackage") {
            try fileManager.copyItem(at: source, to: destinationItem)
        } else if isDirectory.boolValue {
            // Flatten one downloaded wrapper folder so Mirage sees the model
            // weights and companions at the package root.
            let children = try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            for child in children {
                let childDestination = destination.appendingPathComponent(child.lastPathComponent)
                try? fileManager.removeItem(at: childDestination)
                try fileManager.copyItem(at: child, to: childDestination)
            }
        } else {
            try fileManager.copyItem(at: source, to: destinationItem)
        }
    }

    /// Best-effort format inference from a file or folder extension.
    private static func formatForURL(_ url: URL) -> AIModel.ModelFormat {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "mlmodelc", "mlpackage": return .coreML
        case "mlmodel": return .coreML
        case "gguf": return .gguf
        case "safetensors": return .safetensors
        case "bin", "pt", "ckpt", "pth": return .safetensors
        case "json", "txt", "model": return .tokenizer
        default:
            let name = url.lastPathComponent.lowercased()
            if name.contains("lora") { return .lora }
            if name.contains("vae") { return .vae }
            if name.contains("clip") { return .clip }
            return .coreML
        }
    }

    /// Recursive size of a file or directory, in bytes.
    private static func sizeOfItem(at url: URL) -> Int {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if isDir.boolValue {
            guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
            var total = 0
            for case let fileURL as URL in enumerator {
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                total += size
            }
            return total
        }
        return (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }
    
    /// Selects the active model for generation (works for installed models).
    public func selectModel(id: String) {
        print("RepositoryViewModel: Attempting to select model with id: \(id)")
        if let model = models.first(where: { $0.id == id }), model.isInstalled {
            selectedModelId = id
            saveModels()
            print("RepositoryViewModel: Successfully selected model: \(model.name)")
            Logger.info("Active model selected: \(model.name)")
        } else {
            print("RepositoryViewModel: Model not found or not installed: \(id)")
        }
    }
    
    // MARK: - Catalog
    
    /// Built-in list of models that can be downloaded and run on-device.
    ///
    /// Every entry points at a real, non-gated HuggingFace repo verified
    /// against the HF API, and every file is a single self-contained
    /// checkpoint in the A1111 layout that stable-diffusion.cpp (Mirage)
    /// loads directly — text encoders + VAE are embedded in the checkpoint,
    /// so no companion files are needed.
    ///
    /// Generation defaults are tuned per family: SD1.5 is trained at 512px
    /// and wants ~25 steps / CFG ~7; SDXL-family wants 1024px; distilled
    /// models (Turbo) want very few steps and CFG 1.0.
    private static let catalog: [AIModel] = [
        AIModel(id: "sd-1-5", name: "Stable Diffusion 1.5", author: "Stability AI",
                description: "Classic 512px latent-diffusion checkpoint. Smallest download, reliable on-device all-rounder.",
                fileSizeBytes: 4_265_146_304, format: .safetensors, isInstalled: false, isLocalCatalog: true,
                repoId: "runwayml/stable-diffusion-v1-5",
                downloadFiles: ["v1-5-pruned-emaonly.safetensors"],
                defaultSteps: 25, defaultCfgScale: 7.5, recommendedSize: 512),
        AIModel(id: "ssd-1b", name: "SSD-1B", author: "Segmind",
                description: "Distilled SDXL (1.3B UNet). Faster than full SDXL with near-SDXL quality at 1024px.",
                fileSizeBytes: 4_465_671_322, format: .safetensors, isInstalled: false, isLocalCatalog: true,
                repoId: "segmind/SSD-1B",
                downloadFiles: ["SSD-1B-A1111.safetensors"],
                defaultSteps: 25, defaultCfgScale: 6.5, recommendedSize: 1024),
        AIModel(id: "sdxl-base", name: "SDXL Base 1.0", author: "Stability AI",
                description: "Full 1024px SDXL base checkpoint. Highest quality, heaviest on-device load.",
                fileSizeBytes: 6_938_078_334, format: .safetensors, isInstalled: false, isLocalCatalog: true,
                repoId: "stabilityai/stable-diffusion-xl-base-1.0",
                downloadFiles: ["sd_xl_base_1.0.safetensors"],
                defaultSteps: 30, defaultCfgScale: 7.0, recommendedSize: 1024),
        AIModel(id: "sdxl-turbo", name: "SDXL Turbo", author: "Stability AI",
                description: "Distilled one-step SDXL. Set steps low (1-4) and CFG 1.0 for near-instant results.",
                fileSizeBytes: 6_938_081_905, format: .safetensors, isInstalled: false, isLocalCatalog: true,
                repoId: "stabilityai/sdxl-turbo",
                downloadFiles: ["sd_xl_turbo_1.0_fp16.safetensors"],
                defaultSteps: 4, defaultCfgScale: 1.0, recommendedSize: 1024)
    ]
    
    private func saveModels() {
        if let data = try? JSONEncoder().encode(models) {
            UserDefaults.standard.set(data, forKey: "installed_models")
        }
    }
}
