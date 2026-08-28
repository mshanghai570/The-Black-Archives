import CoreGraphics
import Foundation
import CoreML

public final class CoreMLInferenceEngine {
    private var pipelineLoaded = false
    
    public init() {}
    
    public func loadPipeline(modelDirectory: URL) throws {
        // Real CoreML StableDiffusion weights require the apple/ml-stable-diffusion
        // resource loader. We attempt a lightweight readiness check here; when the
        // required .mlmodelc resources are not present on device, generation falls
        // back to the procedural renderer in ImageGenerationService.
        let decoderURL = modelDirectory.appendingPathComponent("VAEDecoder.mlmodelc")
        self.pipelineLoaded = FileManager.default.fileExists(atPath: decoderURL.path)
        if self.pipelineLoaded {
            Logger.info("CoreML pipeline resources detected at \(modelDirectory.path)")
        } else {
            Logger.warning("CoreML resources missing at \(modelDirectory.path); will use procedural fallback.")
        }
    }
    
    public func generateImage(
        prompt: String,
        negativePrompt: String,
        steps: Int,
        size: CGSize,
        seed: UInt32,
        progressHandler: @escaping (Double, String) -> Void
    ) async throws -> CGImage {
        guard pipelineLoaded else {
            throw NSError(domain: "CoreMLInferenceEngine", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Pipeline not loaded. Import a CoreML model first."])
        }
        // When real weights are present, the app would run the StableDiffusionPipeline here.
        // Until then, surface the fallback path.
        throw NSError(domain: "CoreMLInferenceEngine", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "CoreML pipeline unavailable; using procedural fallback."])
    }
}
