import Foundation

public final class HuggingFaceService {
    private let session: URLSession

    public init() {
        let config = URLSessionConfiguration.default
        // Fail fast when the device can't reach HuggingFace: 30s for the first
        // byte, then per-read idle timeout. `waitsForConnectivity` is
        // deliberately OFF — a device that can't reach HF must surface an
        // error banner rather than silently spin at 0% for an hour.
        config.timeoutIntervalForRequest = 30
        // Multi-GB weight downloads on slow links routinely exceed 5 minutes;
        // only give up on the resource timeout after an hour.
        config.timeoutIntervalForResource = 3600
        self.session = URLSession(configuration: config)
    }

    public func searchModels(query: String) async throws -> [AIModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        let endpoint = "https://huggingface.co/api/models?search=\(encodedQuery)&filter=text-to-image&limit=25"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        let (data, _) = try await session.data(from: url)

        struct HFModelResponse: Decodable {
            let id: String
            let author: String?
            let likes: Int?
            let downloads: Int?
            let tags: [String]?
        }

        let hfModels = try JSONDecoder().decode([HFModelResponse].self, from: data)

        return hfModels.map { hf in
            let authorName = hf.author ?? "Unknown"
            let nameOnly = hf.id.split(separator: "/").last.map(String.init) ?? hf.id

            let tags = hf.tags ?? []
            var format: AIModel.ModelFormat = .safetensors
            if tags.contains(where: { $0.lowercased().contains("gguf") }) {
                format = .gguf
            } else if tags.contains(where: { $0.lowercased().contains("coreml") }) {
                format = .coreML
            } else if tags.contains(where: { $0.lowercased().contains("mlx") }) {
                format = .mlx
            } else if tags.contains(where: { $0.lowercased().contains("lora") }) {
                format = .lora
            }

            let desc = "HuggingFace model · \(hf.likes ?? 0) likes · \(hf.downloads ?? 0) downloads"

            return AIModel(
                id: hf.id,
                name: nameOnly,
                author: authorName,
                description: desc,
                fileSizeBytes: 4_500_000_000,
                format: format,
                isInstalled: false,
                localFileURL: nil,
                isLocalCatalog: false
            )
        }
    }

    /// Lists every file in a HuggingFace repo (root-level and nested).
    public func listFiles(repoId: String) async throws -> [(filename: String, size: Int64)] {
        let endpoint = "https://huggingface.co/api/models/\(repoId)"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HuggingFaceService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No response from HuggingFace."])
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HuggingFaceService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Model repo \(repoId) not found (HTTP \(httpResponse.statusCode))."])
        }

        struct Sibling: Decodable {
            let rfilename: String
            let size: Int64?
        }
        struct RepoResponse: Decodable {
            let siblings: [Sibling]?
        }

        let repo = try JSONDecoder().decode(RepoResponse.self, from: data)
        return (repo.siblings ?? []).map { ($0.rfilename, $0.size ?? 0) }
    }

    /// Lists files with checksum information from a HuggingFace repo.
    public func listFilesWithChecksums(repoId: String) async throws -> [(filename: String, size: Int64, sha256: String?)] {
        let endpoint = "https://huggingface.co/api/models/\(repoId)/tree/main"
        guard let url = URL(string: endpoint) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "HuggingFaceService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No response from HuggingFace."])
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HuggingFaceService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Model repo tree not found (HTTP \(httpResponse.statusCode))."])
        }

        struct TreeEntry: Decodable {
            let path: String
            let size: Int64?
            let lfs: [String: String]?
        }

        let entries = try JSONDecoder().decode([TreeEntry].self, from: data)
        return entries.compactMap { entry in
            let sha256 = entry.lfs?["pointer"] ?? entry.lfs?["sha256"] ?? nil
            guard let size = entry.size, size > 0 else { return nil }
            return (entry.path, size, sha256)
        }
    }

    /// Gets checksum for a specific file in a repo.
    public func getFileChecksum(repoId: String, filename: String) async throws -> String? {
        do {
            let files = try await listFilesWithChecksums(repoId: repoId)
            return files.first { $0.filename == filename }?.sha256
        } catch {
            Logger.warning("Failed to get checksum from tree endpoint: \(error.localizedDescription)")
        }

        let shaUrlString = "https://huggingface.co/\(repoId)/resolve/main/SHA256.txt"
        guard let shaUrl = URL(string: shaUrlString) else { return nil }

        do {
            let (data, _) = try await session.data(from: shaUrl)
            let content = String(data: data, encoding: .utf8)
            let lines = content?.components(separatedBy: CharacterSet.newlines) ?? []
            for line in lines {
                let parts = line.components(separatedBy: CharacterSet.whitespaces)
                guard parts.count >= 2 else { continue }
                if parts[1] == filename {
                    return parts[0]
                }
            }
        } catch {
            Logger.info("No SHA256.txt file found for repo \(repoId)")
        }

        return nil
    }

    /// Picks the best single weight file from a repo for local inference.
    ///
    /// Used for arbitrary HuggingFace search results (no manifest).
    /// - Skips non-weight files (docs, configs, subdirectories).
    /// - Skips companion files that are not the diffusion checkpoint itself
    ///   (VAE, text encoders, LoRAs, tokenizers).
    /// - Prefers a quantized GGUF (mid-quants are the sweet spot for on-device
    ///   quality), then falls back to the largest root-level checkpoint.
    public func bestWeightFile(repoId: String) async throws -> (filename: String, size: Int64, format: AIModel.ModelFormat) {
        let files = try await listFiles(repoId: repoId)

        let candidates = files.filter { entry in
            let name = entry.filename
            guard !name.contains("/") else { return false } // root-level only
            let ext = (name as NSString).pathExtension.lowercased()
            guard ["gguf", "safetensors", "ckpt"].contains(ext) else { return false }
            let lower = name.lowercased()
            let companionKeywords = ["vae", "text_encoder", "encoder", "tokenizer", "lora", "clip", "t5", "unet", "onnx"]
            return !companionKeywords.contains(where: { lower.contains($0) })
        }
        guard !candidates.isEmpty else {
            throw NSError(domain: "HuggingFaceService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "No downloadable weight file found in \(repoId)."])
        }

        // Prefer a mid-range GGUF quant; these are the practical on-device pick.
        let quantRank = ["Q4_K_S", "Q4_0", "Q4_K_M", "Q5_0", "Q5_K_S", "Q5_K_M", "Q6_K", "Q8_0", "Q3_K_S", "Q3_K_M", "Q3_K_L", "Q2_K", "F16", "F32"]
        let gguFs = candidates.filter { ($0.filename as NSString).pathExtension.lowercased() == "gguf" }
        if let best = gguFs.min(by: { a, b in
            let ra = quantRank.firstIndex { a.filename.uppercased().contains($0) } ?? 99
            let rb = quantRank.firstIndex { b.filename.uppercased().contains($0) } ?? 99
            if ra != rb { return ra < rb }
            return (a.size > 0 ? a.size : Int64.max) < (b.size > 0 ? b.size : Int64.max)
        }) {
            return (best.filename, best.size, .gguf)
        }

        // Fall back to the largest root checkpoint (full .safetensors/.ckpt).
        if let best = candidates.max(by: { ($0.size > 0 ? $0.size : Int64.max) < ($1.size > 0 ? $1.size : Int64.max) }) {
            let ext = (best.filename as NSString).pathExtension.lowercased()
            let format: AIModel.ModelFormat = ext == "gguf" ? .gguf : .safetensors
            return (best.filename, best.size, format)
        }

        throw NSError(domain: "HuggingFaceService", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "No downloadable weight file found in \(repoId)."])
    }

    /// Downloads a repo file to the given destination URL, reporting progress
    /// as (fraction, receivedBytes, totalBytes).
    ///
    /// Internally this prefers parallel ranged downloads when the server
    /// supports HTTP Range requests, and falls back to single-stream when it
    /// does not. Partial downloads are preserved and resumed across retries.
    ///
    /// - Parameter expectedSize: known byte size of the file (e.g. from the
    ///   repo manifest). Lets the single-stream fallback report real progress
    ///   even when the CDN streams the body without a Content-Length, and
    ///   enables the final size check that catches silent truncation.
    public func downloadFile(
        repoId: String,
        filename: String,
        to destination: URL,
        expectedSize: Int64? = nil,
        onProgress: @escaping (Double, Int64, Int64) -> Void
    ) async throws {
        let resolveURLString = "https://huggingface.co/\(repoId)/resolve/main/\(filename)"
        guard let url = URL(string: resolveURLString) else { throw URLError(.badURL) }

        let manager = ModelDownloadManager(session: session, concurrencyLimit: 6)
        let stream = manager.download(url: url, destination: destination, expectedSize: expectedSize)

        do {
            for try await progress in stream {
                onProgress(progress.fraction, progress.receivedBytes, progress.totalBytes)
            }
        } catch {
            Logger.error("Model download failed for \(filename): \(error.localizedDescription)")
            throw error
        }
    }

    /// Quick pre-flight check that the device can actually reach HuggingFace,
    /// with a short timeout so a dead network path fails fast instead of
    /// silently spinning. Returns nil when reachable, otherwise a
    /// human-readable reason for the failure.
    public func checkConnectivity() async -> String? {
        guard let url = URL(string: "https://huggingface.co/api/models?search=test&limit=1") else {
            return "Invalid check URL."
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) {
                return nil
            }
            return "HuggingFace responded with HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)."
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "Your device has no internet connection."
                case .dataNotAllowed:
                    return "Cellular data is disabled for this app (Settings → Cellular)."
                case .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                    return "Can't reach huggingface.co. Check Wi-Fi/cellular, or the network may be blocking it (VPN, firewall, or region)."
                case .secureConnectionFailed:
                    return "The secure connection to huggingface.co failed."
                default:
                    return "Network error \(urlError.code.rawValue): \(urlError.localizedDescription)"
                }
            }
            return error.localizedDescription
        }
    }

}
