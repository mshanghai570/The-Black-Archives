import CoreGraphics
import Foundation

public final class SafetensorsInferenceEngine {
    public init() {}
    
    public func generateImageSafetensors(prompt: String, steps: Int, size: CGSize, seed: UInt64) async throws -> CGImage {
        throw NSError(domain: "SafetensorsInferenceEngine", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "SafeTensors inference requires custom weight loading. Use MLX engine for .safetensors models."])
    }
}
