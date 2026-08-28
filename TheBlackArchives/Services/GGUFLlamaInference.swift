import CoreGraphics
import Foundation

public final class GGUFLlamaInference {
    public init() {}
    
    public func generateImageGGUF(prompt: String, steps: Int, seed: Int32) async throws -> CGImage {
        throw NSError(domain: "GGUFLlamaInference", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "GGUF inference requires llama.cpp integration. Not yet implemented."])
    }
}
