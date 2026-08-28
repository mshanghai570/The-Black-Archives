import CoreGraphics
import Foundation
import Mirage

/// Real on-device text-to-image engine backed by Mirage (stable-diffusion.cpp).
/// Consumes the user's locally imported GGUF diffusion weights (and optional
/// safetensors VAE / text-encoder companions) and generates a CGImage with no
/// server, no Python conversion step, and no fake fallback.
public final class MirageDiffusionEngine {
    private var engine: Engine?
    public private(set) var loadedModelId: String?

    public init() {}

    /// True when an engine context is already loaded for this model id, so
    /// callers can skip the expensive multi-GB reload between generations.
    public func isLoaded(for modelId: String) -> Bool {
        loadedModelId == modelId && engine != nil
    }

    public func loadPipeline(modelId: String, modelDirectory: URL) throws {
        // The imported model folder may contain a .gguf plus companion
        // .safetensors files (vae / text encoder). Discover them.
        let diffusionModel = Self.pickDiffusionModel(in: modelDirectory)
        let vae = Self.pickCompanion(in: modelDirectory, matching: ["vae", "ae"])
        let textEncoder = Self.pickCompanion(in: modelDirectory, matching: ["text_encoder", "clip", "t5", "encoder"])

        Logger.info("Mirage model directory: \(modelDirectory.path)")
        Logger.info("Mirage discovered files: \(Self.contents(of: modelDirectory).map { $0.lastPathComponent }.joined(separator: ", "))")
        Logger.info("Mirage diffusion model absolute path: \(diffusionModel.path)")
        Logger.info("Mirage diffusion model path exists: \(FileManager.default.fileExists(atPath: diffusionModel.path))")

        // A single file with no companions is a full checkpoint (the catalog's
        // A1111 .safetensors bundle UNet + CLIP + VAE). Load it through
        // `modelPath` so sd.cpp keeps the cond_stage_model.*/first_stage_model.*
        // tensor names — routing it through `diffusionModel` prefix-renames
        // them and the load fails. UNet-only weights with companions keep the
        // three-file layout.
        let models: ModelFiles
        if vae == nil && textEncoder == nil {
            Logger.info("Mirage: Single-file checkpoint mode, using modelPath")
            models = ModelFiles(diffusionModel: diffusionModel, vae: nil, textEncoder: nil, modelPath: diffusionModel)
        } else {
            Logger.info("Mirage: Multi-file mode, using diffusionModel + companions")
            models = ModelFiles(diffusionModel: diffusionModel, vae: vae, textEncoder: textEncoder)
        }

        Logger.info("Mirage loading diffusion model: \(diffusionModel.lastPathComponent)")
        Logger.info("Mirage diffusion model exists: \(FileManager.default.fileExists(atPath: diffusionModel.path))")
        Logger.info("Mirage diffusion model size: \((try? diffusionModel.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) bytes")
        if let v = vae { Logger.info("Mirage VAE: \(v.lastPathComponent)") }
        if let t = textEncoder { Logger.info("Mirage text encoder: \(t.lastPathComponent)") }

        // Verify the model file exists and is not zero bytes
        guard FileManager.default.fileExists(atPath: diffusionModel.path) else {
            throw NSError(domain: "MirageDiffusionEngine", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Diffusion model file not found at \(diffusionModel.path)"])
        }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: diffusionModel.path, isDirectory: &isDir), isDir.boolValue {
            throw NSError(domain: "MirageDiffusionEngine", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Diffusion model path is a directory, not a file: \(diffusionModel.path)"])
        }
        
        if let size = try? diffusionModel.resourceValues(forKeys: [.fileSizeKey]).fileSize, size == 0 {
            throw NSError(domain: "MirageDiffusionEngine", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Diffusion model file is empty at \(diffusionModel.path)"])
        }

        // A corrupt checkpoint is the classic cause of the native engine's
        // generic "model failed to load". Catch it here with a specific,
        // actionable message instead of letting it surface as a mystery:
        // validate the .safetensors header before handing the file to sd.cpp.
        if diffusionModel.pathExtension.lowercased() == "safetensors",
           !ModelManager.isValidSafetensorsHeader(at: diffusionModel) {
            throw NSError(domain: "MirageDiffusionEngine", code: -5,
                          userInfo: [NSLocalizedDescriptionKey: "Model file \(diffusionModel.lastPathComponent) is corrupted (invalid safetensors header) at \(diffusionModel.path). Delete the model and download it again."])
        }

        do {
            self.engine = try Engine(models: models)
        } catch {
            // Bridge MirageError (whose description carries the native sd.cpp
            // reason) to an NSError — plain bridging hides it behind
            // "(mirage.mirageerror error N.)" and leaves users guessing.
            let readable = Self.readableError(error)
            Logger.error("Mirage engine load failed: \(readable.localizedDescription)")
            throw readable
        }
        self.loadedModelId = modelId
    }

    public func generateImage(
        prompt: String,
        negativePrompt: String,
        steps: Int,
        cfgScale: Float,
        size: CGSize,
        seed: UInt64,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> CGImage {
        guard let engine = self.engine else {
            throw NSError(domain: "MirageDiffusionEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Engine not loaded. Import a GGUF model first."])
        }

        let stepCount = max(1, min(steps, 50))
        let width = Self.multipleOfEight(min(max(Int(size.width), 256), 1024))
        let height = Self.multipleOfEight(min(max(Int(size.height), 256), 1024))

        Mirage.setProgressCallback { step, total, _ in
            let fraction = total > 0 ? Double(step) / Double(total) : 0
            progressHandler(fraction, "[Step \(step)/\(total)] Denoising...")
        }
        defer { Mirage.setProgressCallback(nil) }

        let request = GenerationRequest(
            prompt: prompt,
            negativePrompt: negativePrompt.isEmpty ? nil : negativePrompt,
            width: width,
            height: height,
            steps: stepCount,
            cfgScale: cfgScale,
            seed: Int64(seed & 0x7FFFFFFFFFFFFFFF)
        )

        return try await engine.generate(request)
    }

    /// Mirrors a `MirageError` into an `NSError` carrying the native sd.cpp
    /// failure text, so the UI shows a real reason instead of an opaque
    /// `(mirage.mirageerror error N.)` bridged code.
    private static func readableError(_ error: Error) -> Error {
        if let mirageError = error as? MirageError {
            return NSError(domain: "MirageDiffusionEngine", code: 1,
                           userInfo: [NSLocalizedDescriptionKey: mirageError.description])
        }
        return error
    }

    /// sd.cpp requires dimensions to be multiples of 8; round up so a 512- or
    /// 1024-requested size is always accepted.
    private static func multipleOfEight(_ value: Int) -> Int {
        ((value + 7) / 8) * 8
    }

    // MARK: - File discovery

    private static func contents(of dir: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    }

    private static func pickDiffusionModel(in dir: URL) -> URL {
        let files = contents(of: dir)
        let companionKeywords = ["vae", "ae", "text_encoder", "clip", "t5", "encoder", "tokenizer", "lora"]

        func isCompanion(_ url: URL) -> Bool {
            let name = url.lastPathComponent.lowercased()
            return companionKeywords.contains { name.contains($0) }
        }

        // Prefer a GGUF diffusion model that is not a known companion file.
        if let gguf = files.first(where: { $0.pathExtension.lowercased() == "gguf" && !isCompanion($0) }) {
            return gguf
        }
        // Fall back to a safetensors diffusion model that is not a known companion file.
        if let st = files.first(where: { $0.pathExtension.lowercased() == "safetensors" && !isCompanion($0) }) {
            return st
        }
        // Fall back to a ckpt diffusion model that is not a known companion file.
        if let ckpt = files.first(where: { $0.pathExtension.lowercased() == "ckpt" && !isCompanion($0) }) {
            return ckpt
        }
        // Single-file import: the directory itself may be the model.
        if ["gguf", "safetensors", "ckpt"].contains(dir.pathExtension.lowercased()) {
            return dir
        }
        // Last resort: first file in the folder.
        return files.first ?? dir
    }

    private static func pickCompanion(in dir: URL, matching keywords: [String]) -> URL? {
        contents(of: dir).first(where: { url in
            let name = url.lastPathComponent.lowercased()
            let ext = url.pathExtension.lowercased()
            return (ext == "safetensors" || ext == "gguf") &&
                keywords.contains(where: { name.contains($0) })
        })
    }
}
