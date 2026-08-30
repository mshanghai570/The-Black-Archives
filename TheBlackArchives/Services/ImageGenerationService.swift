import CoreGraphics
import Foundation
import ImageIO

public final class ImageGenerationService {
    private let mirageEngine = MirageDiffusionEngine()

    public init() {}

    public func loadPipeline(for model: AIModel) throws {
        let modelURL = ModelManager.shared.getLocalModelURL(id: model.id)
        
        // Check if directory exists and contains valid model files
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: modelURL.path, isDirectory: &isDirectory) else {
            throw NSError(domain: "ImageGenerationService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Model directory not found at \(modelURL.path). Import the model first."])
        }
        
        if isDirectory.boolValue {
            guard ModelManager.hasUsableModelFiles(at: modelURL) else {
                throw NSError(domain: "ImageGenerationService", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "No usable model weights found in \(modelURL.path). The download may be incomplete or incompatible."])
            }
        } else {
            // Single-file import: verify the extension is one Mirage can load.
            let ext = modelURL.pathExtension.lowercased()
            guard ["gguf", "safetensors", "ckpt", "mlmodelc", "mlpackage", "mlmodel"].contains(ext) else {
                throw NSError(domain: "ImageGenerationService", code: -3,
                              userInfo: [NSLocalizedDescriptionKey: "Model file at \(modelURL.path) has unsupported extension '.\(ext)'. Expected .gguf, .safetensors, .ckpt, .mlmodelc, .mlpackage, or .mlmodel."])
            }
        }
        
        try mirageEngine.loadPipeline(modelId: model.id, modelDirectory: modelURL)
    }

    public func generate(
        model: AIModel,
        prompt: String,
        negativePrompt: String = Constants.defaultNegativePrompt,
        steps: Int,
        cfgScale: Float,
        size: CGSize,
        seed: UInt64,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> CGImage {
        let modelURL = ModelManager.shared.getLocalModelURL(id: model.id)
        
        // Check if directory exists and contains valid model files
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: modelURL.path, isDirectory: &isDirectory) else {
            throw NSError(domain: "ImageGenerationService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Model directory not found at \(modelURL.path). Import the model first."])
        }
        
        if isDirectory.boolValue {
            guard ModelManager.hasUsableModelFiles(at: modelURL) else {
                throw NSError(domain: "ImageGenerationService", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "No usable model weights found in \(modelURL.path). The download may be incomplete or incompatible."])
            }
        }

        do {
            // Load the multi-GB weights only once per model; skip the reload
            // when the engine already has this model resident.
            if !mirageEngine.isLoaded(for: model.id) {
                try mirageEngine.loadPipeline(modelId: model.id, modelDirectory: modelURL)
            }
            progressHandler(0.02, "[Core] Running local diffusion engine...")
            return try await mirageEngine.generateImage(
                prompt: prompt,
                negativePrompt: negativePrompt,
                steps: steps,
                cfgScale: cfgScale,
                size: size,
                seed: seed,
                progressHandler: progressHandler
            )
        } catch {
            Logger.error("Local inference failed: \(error.localizedDescription)")
            throw error
        }
    }

    public static func encodePNGData(from cgImage: CGImage) -> Data? {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}
