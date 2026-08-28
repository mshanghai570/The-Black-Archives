import CoreGraphics
import Foundation
import CoreML

public final class MLXInferenceEngine {
    private var pipelineLoaded = false
    
    public init() {}
    
    public func loadPipeline(modelDirectory: URL) throws {
        let decoderURL = modelDirectory.appendingPathComponent("VAEDecoder.mlmodelc")
        self.pipelineLoaded = FileManager.default.fileExists(atPath: decoderURL.path)
        if self.pipelineLoaded {
            Logger.info("MLX pipeline resources detected at \(modelDirectory.path)")
        } else {
            Logger.warning("MLX resources missing at \(modelDirectory.path); will use procedural fallback.")
        }
    }
    
    public func generateImageMLX(
        prompt: String,
        negativePrompt: String = Constants.defaultNegativePrompt,
        steps: Int,
        size: CGSize,
        seed: UInt64,
        progressHandler: @escaping (Double, String) -> Void = { _, _ in }
    ) async throws -> CGImage {
        guard pipelineLoaded else {
            throw NSError(domain: "MLXInferenceEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Pipeline not loaded. Import a model first."])
        }
        throw NSError(domain: "MLXInferenceEngine", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "MLX pipeline unavailable; using procedural fallback."])
    }
}
